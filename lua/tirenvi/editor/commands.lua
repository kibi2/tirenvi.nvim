local api = vim.api -- Neovim

local ui = require("tirenvi.ui") -- Root

local autocmd = require("tirenvi.editor.autocmd") -- Editor
local Debug = require("tirenvi.editor.debug")
local guard = require("tirenvi.editor.guard")

local app = require("tirenvi.app") -- App

local WidthRequest = require("tirenvi.width.request") -- Width

local buf_state = require("tirenvi.io.buf_state") -- IO
local buf_lines = require("tirenvi.io.buf_lines")
local Context = require("tirenvi.io.context")

local notify = require("tirenvi.util.notify") -- Util
local errors = require("tirenvi.util.errors")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param ctx Context
---@param cmd_opts {[string]:any}
---@param sub_cmd_name string
---@param spec {[string]:any}|nil
---@return nil
local function cmd_width(ctx, cmd_opts, sub_cmd_name, spec)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true }) then
		return
	end
	local width_req = WidthRequest.new(cmd_opts, sub_cmd_name, spec)
	if not width_req then
		notify.error(errors.err_invalid_command(cmd_opts.args))
		return
	end
	log.debug(width_req:to_string())
	app.cmd_width(ctx, width_req)
end

---@param ctx Context
---@param cmd_opts {[string]:any}
---@param sub_cmd_name string
---@param spec {[string]:any}|nil
---@return nil
local function cmd_fit(ctx, cmd_opts, sub_cmd_name, spec)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true }) then
		return
	end
	local width_req = WidthRequest.new(cmd_opts, sub_cmd_name, spec)
	if not width_req then
		notify.error(errors.err_invalid_command(cmd_opts.args))
		return
	end
	log.debug(width_req:to_string())
	app.cmd_fit(ctx, width_req)
end

---@param ctx Context
---@param cmd_opts {[string]:any}
---@param sub_cmd_name string
---@return nil
local function cmd_wrap(ctx, cmd_opts, sub_cmd_name)
	if buf_state.should_skip(ctx.bufnr, { has_grid = true }) then
		return
	end
	local width_req = WidthRequest.new(cmd_opts, sub_cmd_name)
	if not width_req then
		notify.error(errors.err_invalid_command(cmd_opts.args))
		return
	end
	log.debug(width_req:to_string())
	app.cmd_wrap(ctx, width_req)
end

---@param ctx Context
---@return nil
local function cmd_toggle(ctx)
	if
		buf_state.should_skip(ctx.bufnr, {
			is_tirbuf = false,
			has_grid = false,
			has_parser = false,
		})
	then
		return
	end
	ui.special_apply(ctx.winid)
	app.toggle(ctx)
	if buf_state.is_tirbuf(ctx.bufnr) then
		autocmd.register_buf_autocmd(ctx.bufnr)
	else
		autocmd.clear_buf_autocmds(ctx.bufnr)
	end
end

---@param ctx Context
---@return nil
local function cmd_redraw(ctx)
	if buf_state.should_skip(ctx.bufnr) then
		return
	end
	app.cmd_redraw(ctx)
end

local warned = false
---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_repair(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then
		return
	end
	local arg = opts.fargs[2]
	if arg == nil then
		if not warned then
			warned = true
			notify.warn(
				"Tir repair is deprecated and will be removed in v0.5. Use :Tir redraw"
			)
		end
		app.cmd_redraw(ctx)
		return
	elseif arg == "toggle" then
		buf_state.set_repair(ctx.bufnr, not buf_state.get_repair(ctx.bufnr))
	elseif arg == "enable" then
		buf_state.set_repair(ctx.bufnr, true)
	elseif arg == "disable" then
		buf_state.set_repair(ctx.bufnr, false)
	else
		notify.error(
			"[Tirenvi] invalid argument: "
				.. arg
				.. " (expected: [enable|disable|toggle])"
		)
		return
	end
	notify.info(
		string.format(
			"[Tirenvi] repair:%s ",
			buf_state.get_repair(ctx.bufnr) and "enable" or "disable"
		)
	)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_debug_read_tir(ctx, opts)
	if buf_state.should_skip(ctx.bufnr, {
		is_tirbuf = false,
	}) then
		return
	end
	local filename = opts.fargs[2]
	if filename == nil then
		notify.error("Tir _read_tir need filename")
		return
	end
	app.debug_read_tir(ctx, filename)
end

---@param ctx Context
---@param opts {[string]:any}
---@return nil
local function cmd_debug_write_tir(ctx, opts)
	if buf_state.should_skip(ctx.bufnr) then
		return
	end
	local filename = opts.fargs[2]
	if filename == nil then
		notify.error("Tir _write_tir need filename")
		return
	end
	app.debug_write_tir(ctx, filename)
end

local command_specs = {
	toggle = { func = cmd_toggle },
	redraw = { func = cmd_redraw },
	width = { func = cmd_width, suffix = { "=", "+", "-", "?" } },
	fit = { func = cmd_fit, suffix = { "=", "+", "-" } },
	wrap = { func = cmd_wrap },
	repair = { func = cmd_repair, suffix = { "toggle", "enable", "diable" } },
	_read_tir = { func = cmd_debug_read_tir },
	_write_tir = { func = cmd_debug_write_tir },
}

local function get_command_keys()
	local keys = {}
	for key, _ in pairs(command_specs) do
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

---@param cmd_opts any
local function on_tir(cmd_opts)
	local sub_cmd = cmd_opts.fargs[1]
	if not sub_cmd then
		notify.info(build_usage())
		return
	end
	local ctx = Context.from_buf()
	local debug_name =
		string.format("%s %s", cmd_opts.name, table.concat(cmd_opts.fargs, " "))
	Debug.ui_entry(ctx.bufnr, debug_name)
	local sub_cmd_name = sub_cmd:match("^[A-Za-z_]+") or ""
	local spec = command_specs[sub_cmd_name]
	if not spec then
		notify.info(build_usage())
		return
	end
	cmd_opts.command = spec
	spec.func(ctx, cmd_opts, sub_cmd_name, spec)
	Debug.ui_exit(ctx.bufnr, debug_name)
end

local function complete_tir(arglead, cmdline)
	local args = vim.split(cmdline, "%s+", { trimempty = true })
	if #args <= 1 then
		return get_command_keys()
	elseif #args == 2 then
		local key = args[2]
		if command_specs[key] then
			return command_specs[key].sub
		end
	end
	return {}
end

local function register_user_command()
	api.nvim_create_user_command("Tir", function(cmd_opts)
		guard.guarded(function()
			on_tir(cmd_opts)
		end)()
	end, {
		nargs = "*",
		range = true,
		complete = complete_tir,
		desc = build_desc(),
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

--#endregion
-- =============================================================================
-- Public API

---@return string
function M.keymap_lf()
	local ctx = Context.from_buf()
	buf_lines.clear_cache()
	log.debug("===+===+===+===+=== keymap_lf %s ===+===+===+===+===", ctx.bufnr)
	if buf_state.should_skip(ctx.bufnr) then
		return util.get_termcodes("<CR>")
	end
	return app.keymap_lf()
end

---@return string
function M.keymap_tab()
	local ctx = Context.from_buf()
	buf_lines.clear_cache()
	log.debug(
		"===+===+===+===+=== keymap_tab %s ===+===+===+===+===",
		ctx.bufnr
	)
	if buf_state.should_skip(ctx.bufnr) then
		return util.get_termcodes("<Tab>")
	end
	return app.keymap_tab()
end

function M.setup()
	register_user_command()
	register_keymaps()
end

return M
