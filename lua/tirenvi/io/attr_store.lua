local config = require("tirenvi.config")
local Attr = require("tirenvi.core.attr")
local namespaces = require("tirenvi.io.namespaces")
local buffer = require("tirenvi.io.buffer")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@param bufnr number
---@param attr Attr
---@param iattr integer
local function show_debug_marks(bufnr, attr, iattr)
    if vim.log.levels.DEBUG < config.log.level then
        return
    end
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
    local attr_long = Attr.get_attr_long(attr)
    local opts = {
        virt_text = { { tostring(attr_long), highlight } },
        virt_text_pos = "eol_right_align", -- eol
    }
    ---- NOTE:
    -- virt_text screen position is not always stable and may differ
    -- from the extmark's actual buffer position.
    vim.api.nvim_buf_set_extmark(bufnr, namespaces.ATTR, start0, 0, opts)
end


-- Public API

---@param ctx Context
---@param attrs Attr[]
function M.write(ctx, attrs)
    M.set_attrs(ctx.bufnr, attrs)
end

---@param ctx Context
---@param req Request
function M.read(ctx, req)
    req.attrs = M.get_attrs(ctx.bufnr)
end

---@param bufnr number
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, namespaces.ATTR, 0, -1)
    buffer.set(bufnr, buffer.IKEY.ATTRS, nil)
end

---@param bufnr number
---@return Attr[]|nil
function M.get_attrs(bufnr)
    return buffer.get(bufnr, buffer.IKEY.ATTRS)
end

---@param bufnr number
function M.set_attrs(bufnr, attrs)
    M.clear(bufnr)
    buffer.set(bufnr, buffer.IKEY.ATTRS, attrs)
    for iattr, attr in ipairs(attrs) do
        show_debug_marks(bufnr, attr, iattr)
    end
end

return M
