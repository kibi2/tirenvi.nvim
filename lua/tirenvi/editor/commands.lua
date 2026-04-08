-- dependencies
local guard = require("tirenvi.util.guard")
local buf_state = require("tirenvi.state.buf_state")
local buffer = require("tirenvi.state.buffer")
local LinProvider = require("tirenvi.state.buffer_line_provider")
local init = require("tirenvi.init")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")
local errors = require("tirenvi.util.errors")
local ui = require("tirenvi.ui")

-- module
local M = {}

local api = vim.api
local fn = vim.fn
-- Public API

-- Command / Keymap handlers (private)
---@param bufnr number
---@param opts {[string]:any}
---@return nil
local function cmd_redraw(bufnr, opts)
	if buf_state.should_skip(bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	init.redraw(bufnr)
end

---@param bufnr number
---@param opts {[string]:any}
---@return nil
local function cmd_toggle(bufnr, opts)
	if buf_state.should_skip(bufnr, {
			supported = true,
			has_parser = true,
		}) then
		return
	end
	ui.special_clear()
	ui.special_apply()
	init.toggle(bufnr)
end

---@param bufnr number
---@param opts {[string]:any}
---@return nil
local function cmd_hbar(bufnr, opts)
	if buf_state.should_skip(bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	init.hbar(bufnr)
end

---@param bufnr number
---@param opts {[string]:any}
---@return nil
local function cmd_width(bufnr, opts)
	if buf_state.should_skip(bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	local operator, num = opts.args:match("^width%s*([=+-]?)(%d*)")
	num = tonumber(num) or 0
	local line_provider = LinProvider.new(bufnr)
	init.width(line_provider, operator, num)
end

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------

local commands = {
	toggle = cmd_toggle,
	redraw = cmd_redraw,
	_hbar = cmd_hbar,
	width = cmd_width,
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
	local command = sub:match("^[A-Za-z_]+") or ""
	if not sub then
		notify.info(build_usage())
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	log.debug("===+===+===+===+=== %s %s[%d] ===+===+===+===+===", opts.name, opts.fargs[1], bufnr)
	local func = commands[command]
	if not func then
		notify.error(errors.err_unknown_command(sub))
		return
	end

	func(bufnr, opts)
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
	local bufnr = vim.api.nvim_get_current_buf()
	vim.keymap.set("i", "<CR>", function()
		return M.keymap_lf(bufnr)
	end, {
		expr = true,
		buffer = 0,
	})
	vim.keymap.set("i", "<Tab>", function()
		return M.keymap_tab(bufnr)
	end, {
		expr = true,
		buffer = 0,
	})
end

---@param bufnr number
---@return string
function M.keymap_lf(bufnr)
	buffer.clear_cache()
	log.debug("===+===+===+===+=== keymap_lf %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr, {
			is_tir_vim = true,
		}) then
		return api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	return init.keymap_lf()
end

---@param bufnr number
---@return string
function M.keymap_tab(bufnr)
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
