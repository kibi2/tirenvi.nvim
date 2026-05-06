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

function Range:__tostring()
    return "range" .. self:short()
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

return Range3
