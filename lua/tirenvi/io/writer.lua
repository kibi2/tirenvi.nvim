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
function M.write(ctx, req)
    buffer.set_lines(ctx.bufnr, req.range.first, req.range.last, req.lines, req.no_undo)
    attr_store.write(ctx, req)
end

return M
