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
    Document.set_max_attr(tirdoc)
end

---@param tirdoc Document
local function max(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            for _, column in ipairs(block.attr.columns) do
                column.width = 0
            end
        end
    end
    Document.set_max_attr(tirdoc)
end

---@param tirdoc Document
---@param ratio number|nil
local function fit(tirdoc, ratio)
    ratio = ratio or math.huge
    local size = buffer.get_text_width()
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            local ncol = block.attr.columns and #block.attr.columns or #block.records
            local width = math.floor((size - ncol - 1) / ncol)
            for _, column in ipairs(block.attr.columns or {}) do
                local auto_plus = math.floor(math.max(column.width, 1) * ratio)
                auto_plus = math.min(auto_plus, 6)
                column.width = math.min(width, column.width + auto_plus)
            end
        end
    end
end

---@param tirdoc Document
local function auto(tirdoc)
    max(tirdoc)
    fit(tirdoc, 0.5)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param width_mode  WidthModeState
---@param tirdoc Document
function M.compute(width_mode, tirdoc)
    if width_mode.mode == "fix" then
        fix(tirdoc)
    elseif width_mode.mode == "max" then
        max(tirdoc)
    elseif width_mode.mode == "fit" then
        fit(tirdoc)
    elseif width_mode.mode == "auto" then
        auto(tirdoc)
    end
end

return M
