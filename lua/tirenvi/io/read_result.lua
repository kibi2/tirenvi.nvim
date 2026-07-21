local Range = require("tirenvi.util.range") -- Util
local log = require("tirenvi.util.log")

-- =============================================================================

---@class ReadResult
---@field range Range
---@field lines string[]
---@field attrs Attr[]
---@field cursor CursorBuf
local M = {}

-- =============================================================================
-- Public API

---@param range Range
---@return ReadResult
function M.new_reader(range)
	return {
		range = range,
	}
end

---@param self ReadResult
---@return integer -- 1-based
---@return integer -- 1-based
function M:lua_range()
	return Range.to_lua(self.range)
end

return M
