-- dependencies
local Context = require("tirenvi.app.context")
local WidthOp = require("tirenvi.width.op")
local buf_state = require("tirenvi.io.buf_state")
local buffer = require("tirenvi.io.buffer")
local init = require("tirenvi.init")
local ui = require("tirenvi.ui")
local guard = require("tirenvi.util.guard")
local notify = require("tirenvi.util.notify")
local errors = require("tirenvi.util.errors")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")
local debug = require("tirenvi.editor.debug")

-- module
local M = {}

local api = vim.api

---@param opts {[string]:any}
---@return integer
---@return integer
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
	return math.min(row_start, row_end), math.min(col_start, col_end)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_width(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true, }) then return end
	local width_op = WidthOp.new(opts)
	if not width_op.opts then
		notify.error(errors.err_unknown_command(opts.args))
		return
	end
	local irow, icol = get_selection(opts)
	log.debug("row:%d, col:%d %s", irow, icol, width_op:to_string())
	init.width(ctx, irow, icol, width_op)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_fit(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true, }) then return end
	local width_op = WidthOp.new(opts)
	if not width_op.opts then
		notify.error(errors.err_unknown_command(opts.args))
		return
	end
	local irow, icol = get_selection(opts)
	log.debug("row:%d, col:%d %s", irow, icol, width_op:to_string())
	init.width(ctx, irow, icol, width_op)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_wrap(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true, }) then return end
	local width_op = WidthOp.new(opts)
	if not width_op.opts then
		notify.error(errors.err_unknown_command(opts.args))
		return
	end
	local irow, icol = get_selection(opts)
	log.debug("row:%d, col:%d %s", irow, icol, width_op:to_string())
	init.width(ctx, irow, icol, width_op)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_toggle(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { is_tirbuf = false, has_grid = true, }) then
		return
	end
	ui.special_apply()
	init.toggle(ctx)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_repair(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	local arg = opts.fargs[2]
	if arg == nil then
		init.repair(ctx)
		return
	elseif arg == "toggle" then
		buffer.set_repair(ctx.bufnr, not buffer.get_repair(ctx.bufnr))
	elseif arg == "enable" then
		buffer.set_repair(ctx.bufnr, true)
	elseif arg == "disable" then
		buffer.set_repair(ctx.bufnr, false)
	else
		notify.error("[Tirenvi] invalid argument: " .. arg .. " (expected: [enable|disable|toggle])")
		return
	end
	notify.info(string.format("[Tirenvi] repair:%s ",
		buffer.get_repair(ctx.bufnr) and "enable" or "disable"))
end

local warned = false
---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_redraw(ctx, opts)
	if not warned then
		warned = true
		notify.warn("Tir redraw is deprecated and will be removed in v0.5. Use :Tir repair")
	end
	cmd_repair(ctx, opts)
end

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------

local commands = {
	toggle = cmd_toggle,
	width = cmd_width,
	fit = cmd_fit,
	wrap = cmd_wrap,
	repair = cmd_repair,
	redraw = cmd_redraw,
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
	local name = string.format("%s %s", opts.name, table.concat(opts.fargs, " "))
	debug.ui_entry(ctx.bufnr, name)
	local func = commands[command]
	if not func then
		notify.error(errors.err_unknown_command(opts.args))
		return
	end
	func(ctx, opts)
	debug.ui_exit(ctx.bufnr, name)
end

local function complete_tir(arglead, cmdline)
	local args = vim.split(cmdline, "%s+", { trimempty = true })
	if #args <= 1 then
		return get_command_keys()
	elseif #args == 2 then
		if args[2] == "width" then
			return {
				"=",
				"+",
				"-",
				"fit",
				"max",
				"fix",
				"toggle",
			}
		end
	end
	return {}
end

local function register_user_command()
	api.nvim_create_user_command("Tir", function(opts)
		guard.guarded(function()
			on_tir(opts)
		end)()
	end, {
		nargs = "*",
		range = true,
		complete = complete_tir,
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

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

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
