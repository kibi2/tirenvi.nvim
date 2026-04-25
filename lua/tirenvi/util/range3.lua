---@class Range3
---@field first integer
---@field last integer
---@field new_last integer

local Range = require("tirenvi.util.range")

local M = {}

---@param self Range3
---@return integer
local function get_delta(self)
    return self.new_last - self.last
end

---@param self Range3
---@return integer
local function get_update(self)
    return self.new_last - self.first
end

---@param first integer
---@param last integer
---@param new_last integer
---@return Range3
function M.new(first, last, new_last)
    return {
        first = first,
        last = last,
        new_last = new_last,
    }
end

---@param self Range3
---@return Range
function M.get_new_range(self)
    return Range.new(self.first, self.new_last)
end

---@param self Range3
---@return string
function M.get_add_str(self)
    return get_delta(self) > 0 and "+" .. tostring(get_delta(self)) or ""
end

---@param self Range3
---@return string
function M.get_remove_str(self)
    return get_delta(self) < 0 and "-" .. tostring(-get_delta(self)) or ""
end

---@param self Range3
---@return string
function M.get_update_str(self)
    return get_update(self) > 0 and "u" .. tostring(get_update(self)) or ""
end

return M
