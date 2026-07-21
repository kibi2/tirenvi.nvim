local buf_lines = require("tirenvi.io.buf_lines") -- IO

-- =============================================================================

---@class BufferLineProvider : LineProvider
local M = {}

-- =============================================================================
-- Public API

---@param bufnr number
---@return BufferLineProvider
function M.new(bufnr)
    return {
        get_lines = function(first, last)
            ---@diagnostic disable-next-line: redundant-parameter
            return buf_lines.get_lines(bufnr, first, last)
        end,

        get_line = function(row)
            ---@diagnostic disable-next-line: redundant-parameter
            return buf_lines.get_line(bufnr, row)
        end,

        line_count = function()
            ---@diagnostic disable-next-line: redundant-parameter
            return buf_lines.line_count(bufnr)
        end,
    }
end

return M
