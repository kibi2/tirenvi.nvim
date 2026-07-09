local Attrs = require("tirenvi.core.attrs")
local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local CursorNvim = require("tirenvi.cursor.nvim")
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
---@pram opts {restore_mode: "none"|"buffer"|"logical"|nil, curosr:boolean|nil}
---@return ReadResult
function M.read(ctx, range, opts)
    opts = opts or {}
    local restore_mode = opts.restore_mode
    local result = ReadResult.new_reader(range)
    result.attrs = attr_store.read(ctx.bufnr)
    local first, last = ReadResult.lua_range(result)
    result.lines = buffer.get_lines(ctx.bufnr, first, last)
    if opts.cursor ~= false then
        result.cursor = M.cursor(ctx)
        result.cursor.restore_mode = restore_mode or "none"
    end
    log.watch("ATTR", Attrs.debug_attrs(result.attrs, "[0]CHACHED ATTRS:"))
    return result
end

---@param ctx Context
---@return CursorBuf
function M.cursor(ctx)
    return CursorNvim.capture(ctx)
end

return M
