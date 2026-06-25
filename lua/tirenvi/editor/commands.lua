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
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")
local debug = require("tirenvi.editor.debug")

-- module
local M = {}

local api = vim.api

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_width(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true, }) then return end
	local width_op = WidthOp.new(opts)
	if not width_op then
		notify.error(errors.err_invalid_command(opts.args))
		return
	end
	log.debug(width_op:to_string())
	init.width(ctx, width_op)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_fit(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true, }) then return end
	local width_op = WidthOp.new(opts)
	if not width_op then
		notify.error(errors.err_invalid_command(opts.args))
		return
	end
	log.debug(width_op:to_string())
	init.fit(ctx, width_op)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_wrap(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true, }) then return end
	local width_op = WidthOp.new(opts)
	if not width_op then
		notify.error(errors.err_invalid_command(opts.args))
		return
	end
	log.debug(width_op:to_string())
	init.wrap(ctx, width_op)
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
local function cmd_redraw(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	init.redraw(ctx)
end

local warned = false
---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_repair(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then return end
	local arg = opts.fargs[2]
	if arg == nil then
		if not warned then
			warned = true
			notify.warn("Tir repair is deprecated and will be removed in v0.5. Use :Tir redraw")
		end
		init.redraw(ctx)
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

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------

local commands = {
	toggle = { func = cmd_toggle, sub = {} },
	redraw = { func = cmd_redraw, sub = {} },
	width = { func = cmd_width, sub = { "=", "+", "-", "?" }, has_op = true },
	fit = { func = cmd_fit, sub = { "=", "+", "-" }, has_op = true },
	wrap = { func = cmd_wrap, sub = {} },
	repair = { func = cmd_repair, sub = { "toggle", "enable", "diable" } },
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
	local ctx = Context.from_buf()
	local debug_name = string.format("%s %s", opts.name, table.concat(opts.fargs, " "))
	debug.ui_entry(ctx.bufnr, debug_name)
	local command_name = sub:match("^[A-Za-z_]+") or ""
	local command = commands[command_name]
	if not command then
		notify.info(build_usage())
		return
	end
	opts.command_name = command_name
	opts.command = command
	command.func(ctx, opts)
	debug.ui_exit(ctx.bufnr, debug_name)
end

local function complete_tir(arglead, cmdline)
	local args = vim.split(cmdline, "%s+", { trimempty = true })
	if #args <= 1 then
		return get_command_keys()
	elseif #args == 2 then
		local key = args[2]
		if commands[key] then
			return commands[key].sub
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
