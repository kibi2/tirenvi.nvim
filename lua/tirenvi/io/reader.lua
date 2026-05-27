local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local Request = require("tirenvi.app.request")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

-- Public API

---@param ctx Context
---@param req Request
---@return string[]
function M.read(ctx, req)
    attr_store.read(ctx, req)
    local allow_plain = ctx.parser.allow_plain or false
    if allow_plain then
        buffer.get_lines(ctx.bufnr, 0, -1)
    end
    local first, last = Request.lua_range(req)
    req.lines = buffer.get_lines(ctx.bufnr, first, last)
    return req.lines
end

return M
