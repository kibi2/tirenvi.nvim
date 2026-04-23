-- dependencies
local Context = require("tirenvi.core.context")
local guard = require("tirenvi.util.guard")
local buf_state = require("tirenvi.state.buf_state")
local buffer = require("tirenvi.state.buffer")
local LinProvider = require("tirenvi.state.buffer_line_provider")
local init = require("tirenvi.init")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")
local errors = require("tirenvi.util.errors")
local Range = require("tirenvi.util.range")
local ui = require("tirenvi.ui")

-- module
local M = {}

local api = vim.api
local fn = vim.fn
-- Public API

-- Command / Keymap handlers (private)
---@param context Context
---@param opts {[string]:any}
---@return nil
local function cmd_reconcile(context, opts)
	if buf_state.should_skip(context.bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	init.reconcile(context)
end

---@param context Context
---@param opts {[string]:any}
---@return nil
local function cmd_toggle(context, opts)
	if buf_state.should_skip(context.bufnr) then return end
	ui.special_apply()
	init.toggle(context)
end

---@param opts {[string]:any}
---@return Rect
local function get_rect(opts)
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

---@param context Context
---@param opts {[string]:any}
---@return nil
local function cmd_width(context, opts)
	if buf_state.should_skip(context.bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	local operator, count = opts.args:match("^width%s*([=+-]?)(%d*)")
	count                 = tonumber(count) or 0
	local rect            = get_rect(opts)
	log.debug("row[%d-%d], col[%d-%d]", rect.row.first, rect.row.last, rect.col.first, rect.col.last)
	local line_provider = LinProvider.new(context)
	init.width(context, line_provider, rect, operator, count)
end

---@param context Context
---@param opts {[string]:any}
---@return nil
local function cmd_auto_reconcile(context, opts)
	if buf_state.should_skip(context.bufnr) then return end
	local arg = opts.fargs[2]
	if arg == nil then
		buffer.set_auto_reconcile(context, not buffer.get_auto_reconcile(context))
	elseif arg == "on" then
		buffer.set_auto_reconcile(context, true)
	elseif arg == "off" then
		buffer.set_auto_reconcile(context, false)
	else
		notify.error("[Tirenvi] invalid argument: " .. arg .. " (expected: on|off)")
		return
	end
	notify.info(string.format("[Tirenvi] auto-reconcile:%s ",
		buffer.get_auto_reconcile(context) and "ON" or "OFF"))
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
	local context = Context.from_buf()
	log.debug("===+===+===+===+=== %s %s[%d] ===+===+===+===+===", opts.name, opts.fargs[1], context.bufnr)
	local func = commands[command]
	if not func then
		notify.error(errors.err_unknown_command(sub))
		return
	end
	func(context, opts)
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

---@return string
function M.keymap_lf()
	local bufnr = Context.from_buf().bufnr
	buffer.clear_cache()
	log.debug("===+===+===+===+=== keymap_lf %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr, {
			is_tir_vim = true,
		}) then
		return api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	return init.keymap_lf()
end

---@return string
function M.keymap_tab()
	local bufnr = Context.from_buf().bufnr
	buffer.clear_cache()
	log.debug("===+===+===+===+=== keymap_tab %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr, {
			is_tir_vim = true,
		}) then
		return api.nvim_replace_termcodes("<Tab>", true, true, true)
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
