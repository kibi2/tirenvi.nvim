-- =============================================================================

---@class CursorTir
---@field restore_mode "none"|"buffer"|"tir"
---@field iblock integer            -- current block index (1-based)
---@field irow integer              -- current row index (1-based)
---@field icol integer              -- current column index (1-based)
---@field col_offset integer        --  current column offset (1-based)
local M = {}

-- =============================================================================
-- Public API

---@param iblock integer
---@param irow integer
---@param icol integer
---@param offset integer
---@return CursorTir
function M.new(iblock, irow, icol, offset)
	---@type CursorTir
	return {
		restore_mode = "none",
		iblock = iblock,
		irow = irow,
		icol = icol,
		col_offset = offset,
	}
end

return M
