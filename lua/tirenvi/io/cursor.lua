-- =============================================================================

---@class CursorBuf
---@field restore_mode "none"|"buffer"|"tir"
---@field row_cur integer           -- current row (1-based)
---@field col_byte integer|nil      -- current column (1-based, byte index)
---@field col_char integer|nil      -- current column (1-based, character index)
---@field col_disp integer|nil      -- current column (1-based, screen index)
---@field line string|nil           -- current line
---@field char string|nil           -- char on cursor
local M = {}

-- =============================================================================
-- Public API

---@param row_cur integer
---@param col_byte integer|nil
---@return CursorBuf
function M.new(row_cur, col_byte)
	---@type CursorBuf
	return {
		restore_mode = "none",
		row_cur = row_cur,
		col_byte = col_byte,
	}
end

---@param row_cur integer
---@param col_disp integer
---@return CursorBuf
function M.new_from_disp(row_cur, col_disp)
	local self = M.new(row_cur, nil)
	self.col_disp = col_disp
	return self
end

return M
