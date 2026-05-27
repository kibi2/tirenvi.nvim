local tir_buf = require("tirenvi.core.tir_buf")
local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local Request = require("tirenvi.app.request")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@param bufnr number
---@param range Range
local function neighbor_has_pipe(bufnr, range)
    local first, last = Range.to_lua(range)
    local line_prev = buffer.get_line(bufnr, first - 1) or ""
    local line_next = buffer.get_line(bufnr, last + 1) or ""
    return tir_buf.has_pipe({ line_prev, line_next })
end

---@param ctx Context
---@param req Request
---@return boolean
local function set_buf(ctx, req)
    local allow_plain = ctx.parser.allow_plain or false
    if allow_plain then
        local lines = buffer.get_lines(ctx.bufnr, 0, -1)
        return tir_buf.has_pipe(lines)
    else
        return neighbor_has_pipe(ctx.bufnr, req.range)
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param req Request
---@return string[]
function M.read(ctx, req)
    req.attrs = attr_store.read(ctx)
    req.is_buf = set_buf(ctx, req)
    local first, last = Request.lua_range(req)
    req.lines = buffer.get_lines(ctx.bufnr, first, last)
    return req.lines
end

return M
