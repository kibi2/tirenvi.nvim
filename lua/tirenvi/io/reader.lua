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
---@pram restore_mode "none"|"buffer"|"logical"|nil
---@return ReadResult
function M.read(ctx, range, restore_mode)
    local result = ReadResult.new_reader(range)
    result.attrs = attr_store.read(ctx.bufnr)
    local first, last = ReadResult.lua_range(result)
    result.lines = buffer.get_lines(ctx.bufnr, first, last)
    local cur_row, _, char_col = buffer.get_cursor_char_pos(ctx)
    result.cursor_info = Attrs.to_logical(result.attrs, cur_row, char_col)
    result.cursor_info.restore_mode = restore_mode or "none"
    log.watch("ATTR", Attrs.debug_attrs(result.attrs, "[0]CHACHED ATTRS:"))
    return result
end

return M
