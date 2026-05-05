---@class Range
---@field first integer
---@field last integer
local Range = {}
Range.__index = Range

---@class Range_whole
Range.WHOLE = setmetatable({}, {
    __index = {
        to_vim = function()
            return 0, -1
        end
    }
})

---@return Range[]
local function sort_range(ranges)
    table.sort(ranges, function(prev, next)
        return prev.first < next.first
    end)
    return ranges
end

---@param prev Range
---@param next Range
---@return Range|nil
local function union_range(prev, next)
    if prev.last + 1 < next.first then
        return nil
    end
    return Range.new(math.min(prev.first, next.first), math.max(prev.last, next.last))
end

function Range:__tostring()
    return "range" .. self:short()
end

---@param first integer
---@param last integer
---@return Range
function Range.new(first, last)
    return setmetatable({
        first = first,
        last = last,
    }, Range)
end

---@return string
function Range:short()
    return string.format("(%d,%d)", self.first, self.last)
end

---@param self Range
---@param target Range
---@return boolean
function Range:intersect(target)
    if self.last < target.first then
        return false
    end
    if target.last < self.first then
        return false
    end
    return true
end

---@param ranges Range[]
---@return Range[]
function Range.union(ranges)
    if #ranges == 0 then
        return ranges
    end
    ranges = sort_range(ranges)
    local unions = { ranges[1] }
    for index = 2, #ranges do
        local merged = union_range(unions[#unions], ranges[index])
        if merged then
            unions[#unions] = merged
        else
            unions[#unions + 1] = ranges[index]
        end
    end
    return unions
end

---@param self Range
---@return integer
---@return integer
function Range:to_vim()
    return self.first, self.last
end

return Range
