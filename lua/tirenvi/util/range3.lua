---@class Range3
---@field first integer
---@field last integer
---@field new_last integer
local Range3 = {}
Range3.__index = Range3

local Range = require("tirenvi.util.range")

---@param self Range3
---@return integer
local function get_delta(self)
    return self.new_last - self.last
end

---@param self Range3
---@return integer
local function get_update(self)
    return math.min(self.new_last, self.last) - self.first + 1
end

---@param self Range3
---@return string
local function get_add_str(self)
    return get_delta(self) > 0 and tostring(get_delta(self) .. "A") or ""
end

---@param self Range3
---@return string
local function get_remove_str(self)
    return get_delta(self) < 0 and tostring(-get_delta(self) .. "D") or ""
end

---@param self Range3
---@return string
local function get_update_str(self)
    return get_update(self) > 0 and tostring(get_update(self) .. "U") or ""
end

---@param self Range3
---@param range Range
local function update_range(self, range)
    if self.first <= range.first and range.first <= self.last then
        range.first = self.first - 1
    end
    if self.first <= range.last and range.last <= self.last then
        range.last = self.last + 1
    end
    local shift = self.new_last - self.last
    if self.last < range.first then
        range.first = range.first + shift
    end
    if self.last < range.last then
        range.last = range.last + shift
    end
    range.first = math.max(range.first, 1)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param first integer -- 1-based
---@param last integer -- 1-based
---@param new_last integer -- 1-based
---@return Range3
function Range3.new(first, last, new_last)
    return setmetatable({
        first = first,
        last = last,
        new_last = new_last,
    }, Range3)
end

---@return string
function Range3:short()
    return string.format("(%d,%d,%d)%s%s%s", self.first, self.last, self.new_last
    , get_add_str(self), get_remove_str(self), get_update_str(self))
end

---@param self Range3
---@return Range
function Range3:get_new_range()
    return Range.from_lua(self.first, self.new_last)
end

---@param self Range3|nil
---@param ranges Range[]
function Range3:update_ranges(ranges)
    if not self then
        return
    end
    for _, range in ipairs(ranges) do
        update_range(self, range)
    end
end

function Range3:is_insert()
    return get_delta(self) > 0 and get_update(self) == 0
end

return Range3
