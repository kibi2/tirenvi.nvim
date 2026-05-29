local Attrs = require("tirenvi.core.attrs")
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
    local result = ReadResult.new_reader(range)
    result.attrs = attr_store.read(ctx)
    result.is_flat = buf_state.is_flat(ctx.bufnr)
    local first, last = ReadResult.lua_range(result)
    result.lines = buffer.get_lines(ctx.bufnr, first, last)
    log.watch("ATTR", Attrs.debug_attrs(result.attrs, "[0]CHACHED ATTRS:"))
    return result
end

return M
