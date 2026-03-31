-- dependencies
local guard = require("tirenvi.util.guard")
local buf_state = require("tirenvi.state.buf_state")
local init = require("tirenvi.init")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")
local errors = require("tirenvi.util.errors")

-- module
local M = {}

local api = vim.api
local fn = vim.fn
-- Public API

-- Command / Keymap handlers (private)
---@param bufnr number
---@return nil
local function cmd_redraw(bufnr)
	log.debug("===+===+===+===+=== redraw %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	init.redraw(bufnr)
end

---@param bufnr number
---@return nil
local function cmd_toggle(bufnr)
	log.debug("===+===+===+===+=== toggle %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr, {
			supported = true,
			has_parser = true,
		}) then
		return
	end
	init.toggle(bufnr)
end

---@param bufnr number
---@return nil
local function cmd_hbar(bufnr)
	log.debug("===+===+===+===+=== hbar %s ===+===+===+===+===", bufnr)
	if buf_state.should_skip(bufnr, {
			ensure_tir_vim = true,
		}) then
		return
	end
	init.hbar(bufnr)
end

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------

local commands = {
	toggle = cmd_toggle,
	redraw = cmd_redraw,
	hbar = cmd_hbar,
}

local function get_command_keys()
	local keys = vim.tbl_keys(commands)
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

	log.debug("===+===+===+===+=== Tir %s ===+===+===+===+===", opts.fargs[1])
	local bufnr = vim.api.nvim_get_current_buf()
	local fn = commands[sub]
	if not fn then
		notify.error(errors.err_unknown_command(sub))
		return
	end

	fn(bufnr)
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
	-- default mapping (only if free)
	if fn.maparg("<C-L>", "n") == "" then
		vim.keymap.set("n", "<C-L>", "<Plug>(tir-redraw)", { silent = true, desc = "Tir redraw" })
	end
end

---@param bufnr number
---@return string
function M.keymap_lf(bufnr)
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
