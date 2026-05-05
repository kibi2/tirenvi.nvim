local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@return Ndjson

-- Public API

---@param ctx Context
---@param req Request
---@return string[]
function M.read(ctx, req)
    attr_store.read(ctx, req)
    req.lines = buffer.get_lines(ctx.bufnr, req.range.first, req.range.last)
    return req.lines
end

return M
