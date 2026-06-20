-- dependencies
local Context = require("tirenvi.app.context")
local Attrs = require("tirenvi.core.attrs")
local Attr = require("tirenvi.core.attr")
local buffer = require("tirenvi.io.buffer")
local buf_state = require("tirenvi.io.buf_state")
local log = require("tirenvi.util.log")

-- module
local M = {}

-- constants / defaults

local bo = vim.bo

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function debug_trace(bufnr, title, name)
    if not log.is_debug() then
        return
    end
    local ctx = Context.from_buf()
    local filetype = bo[ctx.bufnr].filetype
    local state = buf_state.debug_state(ctx.bufnr)
    log.debug("===+=== %s ===+=== %s[#%d] %s : %s ===", title, name or "", bufnr, filetype, state)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function M.ui_entry(bufnr, name)
    debug_trace(bufnr, "ENTRY", name)
end

function M.ui_exit(bufnr, name)
    debug_trace(bufnr, "EXIT!", name)
end

---@param title string
---@return string
function M.cached_attrs(title)
    local attrs = buffer.get(nil, buffer.IKEY.ATTRS)
    return Attrs.debug_attrs(attrs, title)
end

---@return string
function M.cursor_pos()
    local attrs = buffer.get(nil, buffer.IKEY.ATTRS)
    local cur_row, _, char_col = buffer.get_cursor_char_pos()
    local pos = Attrs.to_logical(attrs, cur_row, char_col)
    local str = string.format("cur(%d,%d) b%s:r%s:c%s +(%s,%s)",
        cur_row, char_col,
        pos.iblock,
        pos.irow, pos.icol,
        pos.row_offset, pos.col_offset
    )
    return str
end

---@param iblock integer
---@param irow integer
---@param icol integer
function M.goto(iblock, irow, icol)
    local attrs = buffer.get(nil, buffer.IKEY.ATTRS)
    local cell_pos = {iblock=iblock, irow=irow, icol=icol}
    local char_row, char_col = Attrs.to_cursor(attrs, cell_pos)
    local line = buffer.get_line(nil, char_row)
    local byte_col = vim.str_byteindex(line, char_col - 1)
	buffer.set_cursor_byte_pos(nil, char_row, byte_col)
end

return M
