local Range = require("tirenvi.util.range") -- Util

-- =============================================================================

---@class Range3
---@field first integer
---@field last integer
---@field new_last integer
local Range3 = {}

-- =============================================================================
--#region Private

---@param self Range3
---@return integer
local function get_update(self)
	return math.min(self.new_last, self.last) - self.first + 1
end

---@param self Range3
---@return string
local function get_add_str(self)
	local delta = Range3.get_delta(self)
	return delta > 0 and tostring(delta .. "A") or ""
end

---@param self Range3
---@return string
local function get_remove_str(self)
	local delta = Range3.get_delta(self)
	return delta < 0 and tostring(-delta .. "D") or ""
end

---@param self Range3
---@return string
local function get_update_str(self)
	return get_update(self) > 0 and tostring(get_update(self) .. "U") or ""
end

--#endregion
-- =============================================================================
-- Public API

---@param self Range3
---@return integer
function Range3.get_delta(self)
	return self.new_last - self.last
end

---@param first integer -- 1-based
---@param last integer -- 1-based
---@param new_last integer -- 1-based
---@return Range3
function Range3.new(first, last, new_last)
	return {
		first = first,
		last = last,
		new_last = new_last,
	}
end

---@return string
function Range3:short()
	return string.format(
		"(%d,%d,%d)%s%s%s",
		self.first,
		self.last,
		self.new_last,
		get_add_str(self),
		get_remove_str(self),
		get_update_str(self)
	)
end

---@param self Range3
---@return Range
function Range3:get_new_range()
	return Range.from_lua(self.first, self.new_last)
end

function Range3:is_insert()
	return Range3.get_delta(self) > 0 and get_update(self) == 0
end

return Range3
