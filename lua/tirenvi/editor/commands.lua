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
			unsupported = true,
			has_parser = true,
		}) then
		return
	end
	init.toggle(bufnr)
end

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------

---@param opts any
local function on_tir(opts)
	local args = vim.split(opts.args, " ")
	local sub = args[1]

	if not sub or sub == "" then
		notify.info("Usage: :Tir <toggle|redraw>")
		return
	end

	log.debug("===+===+===+===+=== Tir %s ===+===+===+===+===", args[1])
	if sub == "toggle" then
		cmd_toggle(0)
	elseif sub == "redraw" then
		cmd_redraw(0)
	else
		notify.error(errors.err_unknown_command(sub))
	end
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
			return { "toggle", "redraw" }
		end,
		desc = "Tir command: toggle/redraw",
	})
end

local function register_keymaps()
	vim.keymap.set("i", "<CR>", function()
		return M.keymap_lf(0)
	end, {
		expr = true,
		buffer = 0,
	})
	vim.keymap.set("i", "<Tab>", function()
		return M.keymap_tab(0)
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
