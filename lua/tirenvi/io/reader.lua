local tir_buf = require("tirenvi.core.tir_buf")
local buffer = require("tirenvi.io.buffer")
local buf_state = require("tirenvi.io.buf_state")
local attr_store = require("tirenvi.io.attr_store")
local ReadResult = require("tirenvi.app.read_result")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param range Range
---@return ReadResult
function M.read(ctx, range)
    local req = ReadResult.new_reader(range)
    req.attrs = attr_store.read(ctx)
    req.is_flat = buf_state.is_flat(ctx.bufnr)
    local first, last = ReadResult.lua_range(req)
    req.lines = buffer.get_lines(ctx.bufnr, first, last)
    return req
end

return M
