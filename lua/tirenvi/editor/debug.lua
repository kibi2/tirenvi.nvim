-- dependencies
local Context = require("tirenvi.app.context")
local Attrs = require("tirenvi.core.attrs")
local Attr = require("tirenvi.core.attr")
local buffer = require("tirenvi.io.buffer")
local buf_state = require("tirenvi.io.buf_state")
local log = require("tirenvi.util.log")

-- module
local M = {}

local api         = vim.api

-- constants / defaults

local DELIMITER = " //"
local bo = vim.bo

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param bufnr number
---@param title string
---@param name string
local function debug_trace(bufnr, title, name)
    if not log.is_debug() then
        return
    end
    local ctx = Context.from_buf()
    local filetype = bo[ctx.bufnr].filetype
    local state = buf_state.debug_state(ctx.bufnr)
    log.debug("===+=== %s ===+=== %s[#%d] %s : %s ===", title, name or "", bufnr, filetype, state)
end

---@return string
local function case_tag()
    return vim.g.case_tag or ""
end

---@param info table
---@return string
local function cursor_str(info)
    return string.format("cur(%d,%d) b%s:r%s:c%s +(%s,%s)<%s>",
        info.pos.cur_row,
        info.pos.cur_col,
        info.pos.iblock,
        info.pos.irow, info.pos.icol,
        info.pos.row_offset, info.pos.col_offset,
        info.char
    )
end

---@return table
local function get_info()
    local info = {}
	local ctx                  = Context.from_buf()
    info.attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
    local cur_row, _, char_col = buffer.get_cursor_char_pos(ctx)
    info.pos = Attrs.to_logical(info.attrs, cur_row, char_col)
    info.line = buffer.get_line(ctx.bufnr, cur_row)
    info.char = vim.fn.strcharpart(info.line, char_col - 1, 1)
    return info
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

---@param title string|nil
---@param single boolean|nil
---@return string
function M.layout(title, single)
    single = single or false
    title = case_tag() .. (title or "") .. DELIMITER
    local info = get_info()
    local attr_str = Attrs.debug_attrs(info.attrs, "", info.pos.iblock, info.pos.icol, single)
    return string.format("%s %s %s", title, cursor_str(info), attr_str)
end

---@param title string|nil
---@return string
function M.cursor_pos(title)
    title = case_tag() .. (title or "")
    local info = get_info()
    return string.format("%s%s %s", title, DELIMITER, cursor_str(info))
end

---@param iblock integer
---@param irow integer
---@param icol integer
function M.goto(iblock, irow, icol)
    local ctx = Context.from_buf()
    local attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
    local cell_pos = {iblock=iblock, irow=irow, icol=icol}
    local char_row, char_col = Attrs.to_cursor(attrs, cell_pos)
    local line = buffer.get_line(ctx.bufnr, char_row)
    local byte_col = vim.str_byteindex(line, char_col - 1)
	buffer.set_cursor_byte_pos(ctx.winid, char_row, byte_col)
end

return M
