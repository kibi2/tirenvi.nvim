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

---@param cursor CursorBuf
---@param line string
local function complete(cursor, line)
    cursor.line = line
    local col_char0 = vim.str_utfindex(line, cursor.col_byte - 1)
    local nchar = vim.str_utfindex(line)
    log.assert(col_char0 <= nchar, "col_char0(%d) <= nchar(%d) : %s", col_char0, nchar, line)
    col_char0 = math.min(col_char0, nchar)
    cursor.col_char = col_char0 + 1
    cursor.col_byte = vim.str_byteindex(line, col_char0) + 1
    cursor.char = fn.strcharpart(line, col_char0, 1)
    local prefix = fn.strcharpart(line, 0, col_char0)
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
local function set_cursor(row_cur, col_byte)
    local view = fn.winsaveview()
    view.lnum = row_cur
    view.col = col_byte - 1
    fn.winrestview(view)
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

---@param ctx Context
function M.reset(ctx)
    local cursor = M.capture(ctx)
    set_cursor(cursor.row_cur, cursor.col_byte)
end

---@param ctx Context
---@param row_cur integer
---@param col_byte integer
function M.move(ctx, row_cur, col_byte)
    local cursor = get_cursor(ctx, row_cur, col_byte)
    set_cursor(cursor.row_cur, cursor.col_byte)
end

---@param col_disp integer
---@param line string
---@return integer
local function disp_to_byte(line, col_disp)
    local nchar = vim.str_utfindex(line)
    local disp = 1
    for ichar = 0, nchar - 1 do
        local char = vim.fn.strcharpart(line, ichar, 1)
        local width = vim.fn.strdisplaywidth(char)
        if col_disp < disp + width then
            return vim.str_byteindex(line, ichar) + 1
        end
        disp = disp + width
    end
    return #line + 1
end

---@param line string
---@param row_cur integer
---@param col_disp integer
---@return CursorBuf
function M.from_col_disp(line, row_cur, col_disp)
    local col_byte = disp_to_byte(line, col_disp)
    return Cursor.new(row_cur, col_byte)
end

function M.restore()
end

return M
