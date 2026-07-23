local api = vim.api -- Neovim

local config = require("tirenvi.config") -- Root

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser
local buf_parser = require("tirenvi.parser.buf_parser")

local Context = require("tirenvi.io.context") -- IO
local buf_state = require("tirenvi.io.buf_state")
local buf_lines = require("tirenvi.io.buf_lines")
local CursorNvim = require("tirenvi.io.cursor_nvim")

local errors = require("tirenvi.util.errors") -- Util
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param is_around boolean
local function setup_vl(is_around)
	local ctx = Context.from_buf()
	local count = vim.v.count1
	local cursor_buf = CursorNvim.capture(ctx)
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	local rect = tir_buf.get_block_rect(
		ctx,
		attrs,
		count,
		cursor_buf.row_cur,
		cursor_buf.col_byte,
		is_around
	)
	if not rect then
		return
	end
	local lines = buf_lines.get_lines(ctx.bufnr, rect.row.first, rect.row.last)
	if not buf_parser.table_is_aligned(lines) then
		notify.error(errors.ERR.TABLE_IS_NOT_ALIGNED)
		return
	end
	CursorNvim.move_byte(ctx, rect.row.first, rect.col.first)
	api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
	vim.cmd("normal! o")
	CursorNvim.move_byte(ctx, rect.row.last, rect.col.last)
end

local function setup_vil()
	setup_vl(false)
end

local function setup_val()
	setup_vl(true)
end

--#endregion
-- =============================================================================
-- Public API

function M.setup()
	vim.keymap.set({ "x" }, "i" .. config.textobj.column, setup_vil, {
		desc = "Inner column",
	})
	vim.keymap.set({ "x" }, "a" .. config.textobj.column, setup_val, {
		desc = "Around column",
	})
end

return M
