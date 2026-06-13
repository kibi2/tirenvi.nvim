local Attrs = require("tirenvi.core.attrs")
local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local ReadResult = require("tirenvi.app.read_result")
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
    result.attrs = attr_store.read(ctx.bufnr)
    local first, last = ReadResult.lua_range(result)
    result.lines = buffer.get_lines(ctx.bufnr, first, last)
    log.watch("ATTR", Attrs.debug_attrs(result.attrs, "[0]CHACHED ATTRS:"))
    local sample_first = vim.fn.line("w0")
    local sample_last = vim.fn.line("w$")
    return result
end

return M
