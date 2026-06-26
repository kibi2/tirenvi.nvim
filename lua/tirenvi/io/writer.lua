local Request     = require("tirenvi.app.request")
local Attr        = require("tirenvi.core.attr")
local dirty_range = require("tirenvi.core.dirty_range")
local buffer      = require("tirenvi.io.buffer")
local dirty       = require("tirenvi.io.dirty")
local log         = require("tirenvi.util.log")

local M           = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param bufnr number
---@param cell_pos Cell_pos
local function reset_cursor_pos(bufnr, cell_pos)
    local attrs = buffer.get(bufnr, buffer.IKEY.ATTRS)
    local attr = attrs[cell_pos.iblock]
    if not Attr.is_grid(attr) then
        cell_pos.cur_row = nil
        cell_pos.cur_col = nil
    else
        cell_pos.cur_row = attr.range.first + cell_pos.irow - 1
        cell_pos.cur_col = Attr.get_start_pos(attr, cell_pos.icol)
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param req Request
function M.write(ctx, req)
    reset_cursor_pos(ctx.bufnr, req.cell_pos)
    buffer.set_lines(ctx, req.range, req.lines, Request.is_no_undo(req), req.cell_pos)
    local range3 = Request.get_range3(req)
    local prev_ranges = dirty.get_ranges(ctx.bufnr)
    local new_ranges = dirty_range.remove(prev_ranges, range3)
    dirty.set_ranges(ctx.bufnr, new_ranges)
end

return M
