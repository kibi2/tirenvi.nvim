---@class BufferLineProvider : LineProvider
local buffer = require("tirenvi.state.buffer")

local M = {}

function M.new(bufnr)
    return {
        get_line = function(row)
            ---@diagnostic disable-next-line: redundant-parameter
            return buffer.get_line(bufnr, row - 1)
        end,

        line_count = function()
            ---@diagnostic disable-next-line: redundant-parameter
            return buffer.line_count(bufnr)
        end,
    }
end

return M
