local Document = require("tirenvi.core.document")
local buffer   = require("tirenvi.io.buffer")
local log      = require("tirenvi.util.log")

local M        = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

function M.compute(width_mode, tirdoc)
    if width_mode.mode == "fix" then
        Document.set_auto_attr(tirdoc)
    elseif width_mode.mode == "max" then
        Document.set_auto_attr(tirdoc)
    elseif width_mode.mode == "auto" then
        Document.set_auto_attr(tirdoc)
    elseif width_mode.mode == "fit" then
        local size = buffer.get_text_width()
        for _, block in ipairs(tirdoc.blocks) do
            if block.kind == "grid" then
                local ncol = block.attr.columns and #block.attr.columns or #block.records
                local width = math.floor((size - ncol - 1) / ncol)
                for _, column in ipairs(block.attr.columns or {}) do
                    column.width = width
                end
            end
        end
    end
end

return M
