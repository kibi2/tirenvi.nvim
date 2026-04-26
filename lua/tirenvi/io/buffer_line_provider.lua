local buffer = require("tirenvi.io.buffer")

---@class BufferLineProvider : LineProvider
local M = {}

---@param bufnr number
---@return BufferLineProvider
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
