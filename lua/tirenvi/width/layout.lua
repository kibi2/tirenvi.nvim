local Document = require("tirenvi.core.document")
local Bolck    = require("tirenvi.core.block")
local buffer   = require("tirenvi.io.buffer")
local log      = require("tirenvi.util.log")

local M        = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param tirdoc Document
local function fix(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        for _, column in ipairs(block.attr.columns or {}) do
            column.width = column.fix_width
        end
    end
    Document.set_max_attr(tirdoc)
end

---@param tirdoc Document
local function clear_width(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        for _, column in ipairs(block.attr.columns or {}) do
            column.width = 0
        end
    end
end

---@param tirdoc Document
local function max(tirdoc)
    Document.set_max_attr(tirdoc)
end

---@param block Block
---@param size integer
local function fit_block(block, size)
    local ncol = block.attr.columns and #block.attr.columns or #block.records
    local width = math.floor((size - ncol - 1) / ncol)
    for _, column in ipairs(block.attr.columns or {}) do
        column.width = width
    end
end

---@param tirdoc Document
local function fit(tirdoc)
    local size = buffer.get_text_width()
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            fit_block(block, size)
            log.watch("ATTR", Document.debug_attrs(tirdoc, "[88]MODE"))
        end
    end
end

---@param tirdoc Document
local function auto(tirdoc)
    Document.set_max_attr(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            for _, column in ipairs(block.attr.columns or {}) do
                local plus = math.floor(column.width * 0.3)
                plus = math.max(plus, 1)
                plus = math.min(plus, 5)
                column.width = column.width + plus
            end
        end
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param width_mode  WidthModeState
---@param tirdoc Document
function M.compute(width_mode, tirdoc)
    if width_mode.mode == "fix" then
        fix(tirdoc)
    else
        clear_width(tirdoc)
        if width_mode.mode == "max" then
            max(tirdoc)
        elseif width_mode.mode == "fit" then
            fit(tirdoc)
        elseif width_mode.mode == "auto" then
            auto(tirdoc)
        end
    end
end

return M
