-- dependencies
local Context = require("tirenvi.app.context")
local Attrs = require("tirenvi.core.attrs")
local Attr = require("tirenvi.core.attr")
local CursorNvim = require("tirenvi.cursor.nvim")
local CursorLogical = require("tirenvi.cursor.cursor_logical")
local buffer = require("tirenvi.io.buffer")
local buf_state = require("tirenvi.io.buf_state")
local reader = require("tirenvi.io.reader")
local namespaces = require("tirenvi.io.namespaces")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

-- module
local M = {}

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

---@param cursor CursorBuf
---@param logical CursorLogical
---@return string
local function cursor_str(cursor, logical)
    return string.format("cur(%d,%d) b%s:r%s:c%s%+d<%s>",
        cursor.row_cur,
        cursor.col_disp,
        logical.iblock,
        logical.irow,
        logical.icol,
        logical.col_offset or 0,
        cursor.char
    )
end

---@param ctx Context
---@param attr Attr
---@param iattr integer
---@param icol integer
local function show_attr_marks(ctx, attr, iattr, icol)
    local start0
    if attr.range then
        start0 = Range.to_vim(attr.range)
    else
        start0 = iattr - 1
    end
    local highlight = "ErrorMsg"
    if Attr.is_grid(attr) then
        highlight = "Todo"
    end
    local attr_long = Attr.get_attr_long(attr, icol)
    local opts = {
        virt_text = { { tostring(attr_long), highlight } },
        virt_text_pos = "eol_right_align", -- eol
    }
    ---- NOTE:
    -- virt_text screen position is not always stable and may differ
    -- from the extmark's actual buffer position.
    local nlines = buffer.line_count(ctx.bufnr)
    start0 = math.min(start0, nlines - 1)
    local ok = pcall(vim.api.nvim_buf_set_extmark, ctx.bufnr, namespaces.ATTR, start0, 0, opts)
  if not ok then
    opts = vim.deepcopy(opts)
    opts.virt_text = nil
    opts.virt_text_pos = nil
    vim.api.nvim_buf_set_extmark(ctx.bufnr, namespaces.ATTR, start0, 0, opts)
  end

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
    title = case_tag() .. (title or "") .. DELIMITER
	local ctx                  = Context.from_buf()
    local attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)  or {}
    local cursor = reader.cursor(ctx)
    local logical = Attrs.to_logical(attrs, cursor.row_cur, cursor.col_disp)
    local attr_str = Attrs.debug_attrs(attrs, "", logical.iblock, logical.icol, single)
    return string.format("%s %s %s", title, cursor_str(cursor, logical), attr_str)
end

---@param iblock integer
---@param irow integer
---@param icol integer
function M.goto(iblock, irow, icol)
    local ctx = Context.from_buf()
    local attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
    local logical = CursorLogical.new(iblock, irow, icol, 0)
    local row_cur, col_disp = Attrs.to_cursor(attrs, logical)
    local line = buffer.get_line(ctx.bufnr, row_cur) or ""
    local cursor = CursorNvim.from_col_disp(line, row_cur, col_disp)
	buffer.set_cursor_byte_pos(ctx.winid, row_cur, cursor.col_byte)
end

function M.show_attr_marks(ctx)
    local attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
    vim.api.nvim_buf_clear_namespace(ctx.bufnr, namespaces.ATTR, 0, -1)
    if not attrs then
        return
    end
    local cursor = reader.cursor(ctx)
    local pos = Attrs.to_logical(attrs, cursor.row_cur, cursor.col_disp)
    for iattr, attr in ipairs(attrs) do
        local icol
        if pos.iblock == iattr then
            icol = Attr.to_cell_col(attr, cursor.col_char)
        end
        show_attr_marks(ctx, attr, iattr, icol)
    end
end

return M
