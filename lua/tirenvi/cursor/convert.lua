local Attrs         = require("tirenvi.core.attrs")
local Attr          = require("tirenvi.core.attr")
local bufline       = require("tirenvi.parser.bufline")
local CursorLogical = require("tirenvi.cursor.logical")
local CursorNvim    = require("tirenvi.cursor.nvim")
local log           = require("tirenvi.util.log")

local M             = {}

-- constants / defaults

local fn            = vim.fn

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param cursor_logical CursorLogical
---@param attrs Attr[]
---@param line_provider LineProvider
---@return CursorBuf
function M.to_buf(cursor_logical, attrs, line_provider)
    local row_cur, col_disp = M.to_cursor(attrs, cursor_logical)
    local line = line_provider.get_line(row_cur) or ""
    local prefix = bufline.get_prefix_part(line)
    col_disp = col_disp + fn.strdisplaywidth(prefix)
    local cursor = CursorNvim.from_col_disp(line, row_cur, col_disp)
    return cursor
end

---@param attrs Attr[]
---@param row_cur integer
---@param col_disp integer
---@return CursorLogical
function M.to_logical(attrs, row_cur, col_disp)
    local _, iblock = Attrs.get(attrs, row_cur)
    if not iblock then
        return {}
    end
    local attr = attrs[iblock]
    log.assert(attr, "invalid position %d", row_cur)
    local irow = row_cur - attr.range.first + 1
    local icol, offset = Attr.to_cell_col(attr, col_disp)
    return CursorLogical.new(iblock, irow, icol, offset)
end

---@param attrs Attr[]
---@param logical CursorLogical
---@return integer
---@return integer
function M.to_cursor(attrs, logical)
    local attr = attrs[logical.iblock]
    local row_cur = attr.range.first + logical.irow - 1
    local col_disp = Attr.get_start_pos(attr, logical.icol)
    return row_cur, col_disp
end

return M
