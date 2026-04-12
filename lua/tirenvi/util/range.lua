local M = {}

---@param ranges Range[]
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
local function union_range_2(prev, next)
    if prev.last + 1 < next.first then
        return nil
    end
    return {
        first = math.min(prev.first, next.first),
        last  = math.max(prev.last, next.last),
    }
end

---@param source Range
---@param target Range
---@return boolean
function M.intersect(source, target)
    if source.last < target.first then
        return false
    end
    if target.last < source.first then
        return false
    end
    return true
end

---@param ranges Range[]
---@return Range[]
function M.union(ranges)
    if #ranges == 0 then
        return ranges
    end
    ranges = sort_range(ranges)
    local unions = { ranges[1] }
    for index = 2, #ranges do
        local merged = union_range_2(unions[#unions], ranges[index])
        if merged then
            unions[#unions] = merged
        else
            unions[#unions + 1] = ranges[index]
        end
    end
    return unions
end

return M
