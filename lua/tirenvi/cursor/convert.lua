local Attrs      = require("tirenvi.core.attrs")
local bufline    = require("tirenvi.core.bufline")
local CursorNvim = require("tirenvi.cursor.nvim")
local log        = require("tirenvi.util.log")

local M          = {}

-- constants / defaults

local fn         = vim.fn

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

function M.to_logical(cursor_buf, attrs, line)
end

---@param cursor_logical CursorLogical
---@param attrs Attr[]
---@param line_provider LineProvider
---@return CursorBuf
function M.to_buf(cursor_logical, attrs, line_provider)
    local row_cur, col_disp = Attrs.to_cursor(attrs, cursor_logical)
    local line = line_provider.get_line(row_cur) or ""
    local prefix = bufline.get_prefix_part(line)
    col_disp = col_disp + fn.strdisplaywidth(prefix)
    local cursor = CursorNvim.from_col_disp(line, row_cur, col_disp)
    return cursor
end

return M
