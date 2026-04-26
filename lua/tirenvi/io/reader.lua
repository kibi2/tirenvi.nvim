local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@return Ndjson

-- Public API

---@param request Request
function M.read(request)
    return buffer.get_lines(request.context.bufnr, request.range.first, request.range.last)
end

return M
