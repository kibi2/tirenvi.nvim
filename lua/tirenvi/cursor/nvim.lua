local Cursor = require("tirenvi.cursor.cursor_buf")
local log    = require("tirenvi.util.log")

local M      = {}

-- constants / defaults

local api    = vim.api
local fn     = vim.fn
local bo     = vim.bo
local b      = vim.b

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param line string
---@param col_char integer
---@return integer -- byte index (1-based)
local function char_to_byte(line, col_char)
    local nchar = vim.str_utfindex(line) + 1
    log.assert(col_char <= nchar, "col_char(%d) <= nchar(%d) : %s", col_char, nchar, line)
    col_char = math.min(col_char, nchar)
    -- str_byteindex(line, "utf-32", col_char - 1, false)
    return vim.str_byteindex(line, col_char - 1) + 1
end

---@param cursor CursorBuf
---@param line string
local function complete(cursor, line)
    cursor.line = line
    cursor.col_char = vim.str_utfindex(line, cursor.col_byte - 1) + 1
    cursor.col_byte = char_to_byte(line, cursor.col_char)
    cursor.char = fn.strcharpart(line, cursor.col_char - 1, 1)
    local prefix = fn.strcharpart(line, 0, cursor.col_char - 1)
    cursor.col_disp = fn.strdisplaywidth(prefix) + 1
end

---@param ctx Context
---@param row_cur integer
---@param col_byte integer
---@return CursorBuf
local function get_cursor(ctx, row_cur, col_byte)
    local cursor = Cursor.new(row_cur, col_byte)
    local line = ctx.line_provider.get_line(cursor.row_cur) or ""
    complete(cursor, line)
    return cursor
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
        local char = vim.fn.strcharpart(line, ichar - 1, 1)
        local width = vim.fn.strdisplaywidth(char)
        if col_disp < disp + width then
            return char_to_byte(line, ichar)
        end
        disp = disp + width
    end
    return #line + 1
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

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
    return Cursor.new(row_cur, col_byte)
end

---@param ctx Context
function M.reset(ctx)
    local cursor = M.capture(ctx)
    restore_cursor(cursor.row_cur, cursor.col_byte)
end

--- Normal cursor movement.
--- Preserves window view and preferred column.
---@param ctx Context
---@param row_cur integer
---@param col_byte integer
function M.restore_byte(ctx, row_cur, col_byte)
    local cursor = get_cursor(ctx, row_cur, col_byte)
    restore_cursor(cursor.row_cur, cursor.col_byte)
end

---@param ctx Context
---@param row_cur integer
---@param col_disp integer
function M.restore_disp(ctx, row_cur, col_disp)
    local line = ctx.line_provider.get_line(row_cur) or ""
    local cursor = M.from_col_disp(line, row_cur, col_disp)
    M.restore_byte(ctx, row_cur, cursor.col_byte)
end

--- Direct cursor update.
--- Use for Visual/Visual Block.
---@param ctx Context
---@param row_cur integer
---@param col_byte integer
function M.move_byte(ctx, row_cur, col_byte)
    api.nvim_win_set_cursor(ctx.winid, { row_cur, math.max(0, col_byte - 1) })
end

function M.restore()
end

return M
