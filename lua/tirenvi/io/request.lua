local Range = require("tirenvi.util.range") -- Util
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

-- =============================================================================

---@class Request
---@field range Range
---@field lines string[]
---@field no_undo boolean
---@field cursor_buf CursorBuf
local M = {}

-- =============================================================================
-- Public API

---@param r_req ReadResult
---@param lines string[]
---@param no_undo boolean|nil
---@return Request
function M.new_writer(r_req, lines, no_undo)
	---@type Request
	return {
		range = r_req.range,
		lines = lines,
		no_undo = no_undo or false,
		cursor_buf = r_req.cursor_buf,
	}
end

---@param self Request
---@return Range3
function M:get_range3()
	local first, last = Range.to_lua(self.range)
	return Range3.new(first, last, first + #self.lines - 1)
end

---@param self Request
---@return boolean
function M:is_no_undo()
	return self.no_undo == true
end

return M
