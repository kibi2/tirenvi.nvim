local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@return Ndjson

-- Public API

---@param request Request
---@return string[]
function M.read(request)
    attr_store.read(request)
    request.lines = buffer.get_lines(request.context.bufnr, request.range.first, request.range.last)
    return request.lines
end

return M
