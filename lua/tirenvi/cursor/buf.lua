---@class CursorBuf
---@field restore_mode "none"|"buffer"|"logical"
---@field row_cur integer           -- current row (1-based)
---@field col_byte integer          -- current column (1-based, byte index)
---@field col_char integer|nil      -- current column (1-based, character index)
---@field col_disp integer|nil      -- current column (1-based, screen index)
---@field line string|nil           -- current line
---@field char string|nil           -- char on cursor

local M = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param row_cur integer
---@param col_byte integer
---@return CursorBuf
function M.new(row_cur, col_byte)
    return {
        row_cur = row_cur,
        col_byte = col_byte,
    }
end

return M
