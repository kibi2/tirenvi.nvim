local dirty_range = require("tirenvi.parser.dirty_range") -- Parser

local buf_lines = require("tirenvi.io.buf_lines") -- IO
local dirty = require("tirenvi.io.dirty")
local Request = require("tirenvi.io.request")

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param ctx Context
---@param req Request
function M.write(ctx, req)
	buf_lines.set_lines(
		ctx,
		req.range,
		req.lines,
		Request.is_no_undo(req),
		req.cursor
	)
	local range3 = Request.get_range3(req)
	local prev_ranges = dirty.get_ranges(ctx.bufnr)
	local new_ranges = dirty_range.remove(prev_ranges, range3)
	dirty.set_ranges(ctx.bufnr, new_ranges)
end

return M
