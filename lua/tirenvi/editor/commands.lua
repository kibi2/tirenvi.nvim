-- dependencies
local Context = require("tirenvi.app.context")
local Cell = require("tirenvi.core.cell")
local guard = require("tirenvi.util.guard")
local buf_state = require("tirenvi.io.buf_state")
local buffer = require("tirenvi.io.buffer")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local init = require("tirenvi.init")
local notify = require("tirenvi.util.notify")
local errors = require("tirenvi.util.errors")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")
local ui = require("tirenvi.ui")
local log = require("tirenvi.util.log")

-- module
local M = {}

local api = vim.api
local fn = vim.fn

---@class WidthOp
---@field operator '"="'|'"+"'|'"-"'
---@field kind '"set"'|'"add"'|'"sub"'|'"auto"'|nil
---@field count_str string
---@field count integer
local WidthOp = {}
WidthOp.__index = WidthOp

local map = {
	["+"] = "add",
	["-"] = "sub",
	["="] = "set",
}

---@param width_op WidthOp
---@return '"set"'|'"add"'|'"sub"'|'"auto"'|nil
local function to_kind(width_op)
	local operator = width_op.operator
	if operator == "" then
		operator = "="
	end
	return map[operator]
end

---@param args string
---@return WidthOp
function WidthOp.new(args)
	local self                    = setmetatable({}, WidthOp)
	self.operator, self.count_str = args:match("^width%s*([=+-]?)(%d*)")
	self.kind                     = to_kind(self)
	self.count                    = tonumber(self.count_str) or 1
	if self.count < 1 then
		self.count = 1
	end
	if self.kind == "set" and self.count <= 1 then
		self.kind = "auto"
		self.count = 0
	end
	return self
end

function WidthOp:to_cmd()
	return string.format(":<C-u>Tir width %s%s<CR>", self.operator, self.count_str)
end

function WidthOp:to_string()
	return string.format("WidthOp %s:%d %s", self.kind, self.count, self:to_cmd())
end

---@param current integer
---@param max integer
---@return integer
function WidthOp:apply(current, max)
	if self.kind == "set" then
		return math.max(self.count, Cell.MIN_WIDTH)
	elseif self.kind == "add" then
		return current + self.count
	elseif self.kind == "sub" then
		return math.max(current - self.count, Cell.MIN_WIDTH)
	elseif self.kind == "auto" then
		return max or 2
	else
		return current
	end
end

-- Command / Keymap handlers (private)
---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_reconcile(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	init.reconcile(ctx)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_toggle(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	ui.special_apply()
	init.toggle(ctx)
end

---@param opts {[string]:any}
---@return Rect
local function get_selection(opts)
	local row_start = opts.line1
	local row_end   = opts.line2
	local is_block  = (vim.fn.visualmode() == "\22")
	local col_start, col_end
	if opts.range > 0 then
		if is_block then
			col_start = vim.fn.virtcol("'<")
			col_end   = vim.fn.virtcol("'>")
		else
			col_start = 1
			col_end   = math.huge
		end
	else
		local col = vim.fn.virtcol(".")
		col_start = col
		col_end   = col
	end
	return {
		row = Range.new(math.min(row_start, row_end), math.max(row_start, row_end)),
		col = Range.new(math.min(col_start, col_end), math.max(col_start, col_end)),
	}
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_width(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	local width_op = WidthOp.new(opts.args)
	local sel      = get_selection(opts)
	log.debug("row[%d-%d], col[%d-%d] %s", sel.row.first, sel.row.last, sel.col.first, sel.col.last,
		width_op:to_string())
	local line_provider = LinProvider.new(ctx.bufnr)
	init.width(ctx, line_provider, sel, width_op)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_auto_reconcile(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	local arg = opts.fargs[2]
	if arg == nil then
		buffer.set_auto_reconcile(ctx.bufnr, not buffer.get_auto_reconcile(ctx.bufnr))
	elseif arg == "on" then
		buffer.set_auto_reconcile(ctx.bufnr, true)
	elseif arg == "off" then
		buffer.set_auto_reconcile(ctx.bufnr, false)
	else
		notify.error("[Tirenvi] invalid argument: " .. arg .. " (expected: on|off)")
		return
	end
	notify.info(string.format("[Tirenvi] auto-reconcile:%s ",
		buffer.get_auto_reconcile(ctx.bufnr) and "ON" or "OFF"))
end

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------

local commands = {
	toggle = cmd_toggle,
	redraw = cmd_reconcile,
	_reconcile = cmd_reconcile,
	width = cmd_width,
	["_auto-reconcile"] = cmd_auto_reconcile,
}


local function get_command_keys()
	local keys = {}
	for key, _ in pairs(commands) do
		if not key:match("^_") then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	return keys
end

local function build_usage()
	return "Usage: :Tir <" .. table.concat(get_command_keys(), "|") .. ">"
end

local function build_desc()
	return "Tir command: " .. table.concat(get_command_keys(), "/")
end

---@param opts any
local function on_tir(opts)
	local sub = opts.fargs[1]
	if not sub then
		notify.info(build_usage())
		return
	end
	local command = sub:match("^[A-Za-z_-]+") or ""
	if command == "width-" then
		command = "width"
	end
	local ctx = Context.from_buf()
	log.debug("===+===+===+===+=== %s %s[%d] ===+===+===+===+===", opts.name, opts.fargs[1], ctx.bufnr)
	local func = commands[command]
	if not func then
		notify.error(errors.err_unknown_command(sub))
		return
	end
	func(ctx, opts)
end

local function register_user_command()
	api.nvim_create_user_command("Tir", function(opts)
		guard.guarded(function()
			on_tir(opts)
		end)()
	end, {
		nargs = "*",
		range = true,
		complete = function()
			return get_command_keys()
		end,
		desc = build_desc()
	})
end

local function register_keymaps()
	vim.keymap.set("i", "<CR>", function()
		return M.keymap_lf()
	end, {
		expr = true,
		buffer = 0,
	})
	vim.keymap.set("i", "<Tab>", function()
		return M.keymap_tab()
	end, {
		expr = true,
		buffer = 0,
	})
end

-- Public API

---@return string
function M.keymap_lf()
	local bufnr = Context.from_buf().bufnr
	buffer.clear_cache()
	log.debug("===+===+===+===+=== keymap_lf %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr) then
		return util.get_termcodes("<CR>")
	end
	return init.keymap_lf()
end

---@return string
function M.keymap_tab()
	local bufnr = Context.from_buf().bufnr
	buffer.clear_cache()
	log.debug("===+===+===+===+=== keymap_tab %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr) then
		return util.get_termcodes("<Tab>")
	end
	return init.keymap_tab()
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------

function M.setup()
	register_user_command()
	register_keymaps()
end

return M
