---@class BufferLineProvider : LineProvider
local Context = require("tirenvi.core.context")
local buffer = require("tirenvi.state.buffer")

local M = {}

---@param context Context|nil
---@return BufferLineProvider
function M.new(context)
    context = context or Context.from_buf()
    return {
        get_line = function(row)
            ---@diagnostic disable-next-line: redundant-parameter
            return buffer.get_line(context.bufnr, row - 1)
        end,

        line_count = function()
            ---@diagnostic disable-next-line: redundant-parameter
            return buffer.line_count(context.bufnr)
        end,
    }
end

return M
