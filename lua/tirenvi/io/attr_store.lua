local config = require("tirenvi.config")
local Attr = require("tirenvi.core.attr")
local Attrs = require("tirenvi.core.attrs")
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

---@param attrs Attr[]
local function set_fix_width(attrs)
    for _, attr in ipairs(attrs) do
        if attr.width_mode and attr.width_mode.mode == "fix" then
            for _, column in ipairs(attr.columns or {}) do
                column.fix_width = column.width
            end
        end
    end
end

---@param bufnr number
---@param attrs Attr[]|nil
local function set_attrs(bufnr, attrs)
    --local width_mode = buffer.get(bufnr, buffer.IKEY.WIDTH_MODE)
    --if width_mode.mode == "fix" then
    set_fix_width(attrs or {})
    --end
    buffer.set(bufnr, buffer.IKEY.ATTRS, attrs)
    log.probe(Attrs.debug_attrs(attrs, "[88]MODE:"))
    vim.schedule(function()
        vim.api.nvim_buf_clear_namespace(bufnr, namespaces.ATTR, 0, -1)
        for iattr, attr in ipairs(attrs or {}) do
            show_debug_marks(bufnr, attr, iattr)
        end
    end)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number|nil
---@return Attr[]
function M.read(bufnr)
    return buffer.get(bufnr, buffer.IKEY.ATTRS) or {}
end

---@param bufnr number
---@param attrs Attr[]|nil
function M.write(bufnr, attrs)
    set_attrs(bufnr, attrs)
end

return M
