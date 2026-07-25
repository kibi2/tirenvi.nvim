local api = vim.api -- Neovim

local config = require("tirenvi.config") -- Root

local buf_parser = require("tirenvi.parser.buf_parser") -- Parser
local tir_buf = require("tirenvi.parser.tir_buf")

local Context = require("tirenvi.io.context") -- IO
local buf_state = require("tirenvi.io.buf_state")
local buf_lines = require("tirenvi.io.buf_lines")
local CursorNvim = require("tirenvi.io.cursor_nvim")

local Attrs = require("tirenvi.core.attrs") -- Core

local Range = require("tirenvi.util.range") -- Util
local errors = require("tirenvi.util.errors")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param ctx Context
---@param attrs Attr[]
---@param count integer
---@param row_cur integer
---@param col_byte integer
---@param is_around boolean
---@return Rect|nil
local function get_block_rect(ctx, attrs, count, row_cur, col_byte, is_around)
	local attr = Attrs.get(attrs, row_cur)
	if not attr then
		return nil
	end
	local cline = ctx.line_provider.get_line(row_cur) or ""
	local cbyte_pos = tir_buf.get_pipe_byte_positions(cline)
	if #cbyte_pos == 0 then
		return nil
	end
	local icol_start = tir_buf.get_current_col_index(cbyte_pos, col_byte)
	if not icol_start or icol_start == 0 then
		return nil
	end
	icol_start = math.min(icol_start, #cbyte_pos - 1)
	local tline = ctx.line_provider.get_line(attr.range.first) or ""
	local bline = ctx.line_provider.get_line(attr.range.last) or ""
	local tbyte_pos = tir_buf.get_pipe_byte_positions(tline)
	local bbyte_pos = tir_buf.get_pipe_byte_positions(bline)
	local icol_end = icol_start + count
	icol_end = math.min(icol_end, #bbyte_pos)
	local pipe = tir_buf.get_pipe_char(tline)
	local rect = {
		row = Range.copy(attr.range),
		col = Range.from_lua(
			tbyte_pos[icol_start] + (is_around and 0 or #pipe),
			bbyte_pos[icol_end] - 1
		),
	}
	return rect
end

---@param is_around boolean
local function setup_vl(is_around)
	local ctx = Context.from_buf()
	local count = vim.v.count1
	local cursor_buf = CursorNvim.capture(ctx)
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	local rect = get_block_rect(
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
