local Request     = require("tirenvi.app.request")
local dirty_range = require("tirenvi.parser.dirty_range")
local buffer      = require("tirenvi.io.buffer")
local dirty       = require("tirenvi.io.dirty")
local log         = require("tirenvi.util.log")

local M           = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param req Request
function M.write(ctx, req)
    buffer.set_lines(ctx, req.range, req.lines, Request.is_no_undo(req), req.cursor)
    local range3 = Request.get_range3(req)
    local prev_ranges = dirty.get_ranges(ctx.bufnr)
    local new_ranges = dirty_range.remove(prev_ranges, range3)
    dirty.set_ranges(ctx.bufnr, new_ranges)
end

return M
