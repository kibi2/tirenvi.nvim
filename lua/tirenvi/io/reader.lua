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
    local r_result = ReadResult.new_reader(range)
    r_result.attrs = attr_store.read(ctx)
    r_result.is_flat = buf_state.is_flat(ctx.bufnr)
    local first, last = ReadResult.lua_range(r_result)
    r_result.lines = buffer.get_lines(ctx.bufnr, first, last)
    return r_result
end

return M
