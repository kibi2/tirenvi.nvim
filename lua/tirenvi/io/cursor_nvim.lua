local api = vim.api -- Neovim
local fn = vim.fn

local CursorBuf = require("tirenvi.io.cursor") -- IO

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param line string
---@param col_char integer
---@return integer -- byte index (1-based)
local function char_to_byte(line, col_char)
	local nchar = vim.str_utfindex(line) + 1
	log.assert(
		col_char <= nchar,
		"col_char(%d) <= nchar(%d) : %s",
		col_char,
		nchar,
		line
	)
	col_char = math.min(col_char, nchar)
	-- str_byteindex(line, "utf-32", col_char - 1, false)
	return vim.str_byteindex(line, col_char - 1) + 1
end

---@param cursor_buf CursorBuf
---@param line string
local function complete(cursor_buf, line)
	cursor_buf.line = line
	cursor_buf.col_char = vim.str_utfindex(line, cursor_buf.col_byte - 1) + 1
	cursor_buf.col_byte = char_to_byte(line, cursor_buf.col_char)
	cursor_buf.char = fn.strcharpart(line, cursor_buf.col_char - 1, 1)
	local prefix = fn.strcharpart(line, 0, cursor_buf.col_char - 1)
	cursor_buf.col_disp = fn.strdisplaywidth(prefix) + 1
end

---@param ctx Context
---@param row_cur integer
---@param col_byte integer
---@return CursorBuf
local function get_cursor(ctx, row_cur, col_byte)
	local cursor_buf = CursorBuf.new(row_cur, col_byte)
	local line = ctx.line_provider.get_line(cursor_buf.row_cur) or ""
	complete(cursor_buf, line)
	return cursor_buf
end

---@param row_cur integer
---@param col_byte integer
local function restore_cursor(row_cur, col_byte)
	local view = fn.winsaveview()
	view.lnum = row_cur
	view.col = col_byte - 1
	fn.winrestview(view)
end

---@param col_disp integer
---@param line string
---@return integer
local function disp_to_byte(line, col_disp)
	local nchar = vim.str_utfindex(line)
	local disp = 1
	for ichar = 1, nchar do
		local char = fn.strcharpart(line, ichar - 1, 1)
		local width = fn.strdisplaywidth(char)
		if col_disp < disp + width then
			return char_to_byte(line, ichar)
		end
		disp = disp + width
	end
	return #line + 1
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@return CursorBuf
function M.capture(ctx)
	local row_cur, col_byte0 = unpack(api.nvim_win_get_cursor(ctx.winid))
	return get_cursor(ctx, row_cur, col_byte0 + 1)
end

---@param line string
---@param row_cur integer
---@param col_disp integer
---@return CursorBuf
function M.from_col_disp(line, row_cur, col_disp)
	local col_byte = disp_to_byte(line, col_disp)
	return CursorBuf.new(row_cur, col_byte)
end

---@param ctx Context
function M.reset(ctx)
	local cursor_buf = M.capture(ctx)
	restore_cursor(cursor_buf.row_cur, cursor_buf.col_byte)
end

--- Normal cursor movement.
--- Preserves window view and preferred column.
---@param ctx Context
---@param row_cur integer
---@param col_byte integer
function M.restore_byte(ctx, row_cur, col_byte)
	local cursor_buf = get_cursor(ctx, row_cur, col_byte)
	restore_cursor(cursor_buf.row_cur, cursor_buf.col_byte)
end

---@param ctx Context
---@param row_cur integer
---@param col_disp integer
function M.restore_disp(ctx, row_cur, col_disp)
	local line = ctx.line_provider.get_line(row_cur) or ""
	local cursor_buf = M.from_col_disp(line, row_cur, col_disp)
	M.restore_byte(ctx, row_cur, cursor_buf.col_byte)
end

--- Direct cursor update.
--- Use for Visual/Visual Block.
---@param ctx Context
---@param row_cur integer
---@param col_byte integer
function M.move_byte(ctx, row_cur, col_byte)
	api.nvim_win_set_cursor(ctx.winid, { row_cur, math.max(0, col_byte - 1) })
end

function M.restore() end

return M
