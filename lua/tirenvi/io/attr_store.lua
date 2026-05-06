local buffer = require("tirenvi.io.buffer")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@return Ndjson

-- Public API

---@param ctx Context
---@param req Request
function M.write(ctx, req)
    if not req.attrs then
        log.watch("ATTR", "nil")
        return
    end
    log.watch("ATTR", req.attrs)
    buffer.set(ctx.bufnr, buffer.IKEY.ATTRS, req.attrs)
end

---@param ctx Context
---@param req Request
function M.read(ctx, req)
    req.attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
    log.watch("ATTR", req.attrs)
end

---@param ctx Context
function M.clear(ctx)
    buffer.set(ctx.bufnr, buffer.IKEY.ATTRS, nil)
end

return M
