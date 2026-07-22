local fn = vim.fn -- Neovim

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser

local Attrs = require("tirenvi.core.attrs") -- Core
local Attr = require("tirenvi.core.attr")
local CursorTir = require("tirenvi.core.cursor")

local CursorNvim = require("tirenvi.io.cursor_nvim") -- IO

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param cursor_tir CursorTir
---@param attrs Attr[]
---@param line_provider LineProvider
---@return CursorBuf
function M.to_buf(cursor_tir, attrs, line_provider)
	local row_cur, col_disp = M.to_cursor(attrs, cursor_tir)
	local line = line_provider.get_line(row_cur) or ""
	local prefix = tir_buf.get_prefix_part(line)
	col_disp = col_disp + fn.strdisplaywidth(prefix)
	local cursor_buf = CursorNvim.from_col_disp(line, row_cur, col_disp)
	return cursor_buf
end

---@param attrs Attr[]
---@param row_cur integer
---@param col_disp integer
---@return CursorTir
function M.to_tir(attrs, row_cur, col_disp)
	local _, iblock = Attrs.get(attrs, row_cur)
	if not iblock then
		return {}
	end
	local attr = attrs[iblock]
	log.assert(attr, "invalid position %d", row_cur)
	local irow = row_cur - attr.range.first + 1
	local icol, offset = Attr.to_cell_col(attr, col_disp)
	return CursorTir.new(iblock, irow, icol, offset)
end

---@param attrs Attr[]
---@param cursor_tir CursorTir
---@return integer
---@return integer
function M.to_cursor(attrs, cursor_tir)
	local attr = attrs[cursor_tir.iblock]
	local row_cur = attr.range.first + cursor_tir.irow - 1
	local col_disp = Attr.get_start_pos(attr, cursor_tir.icol)
	return row_cur, col_disp
end

return M
