---@class Range
---@field first integer
---@field last integer

local log = require("tirenvi.util.log")

local M   = {}

local api = vim.api

---@param first integer
---@param last integer
---@return Range
local function new(first, last)
    if first > last then
        -- TODO
        -- log.error("invalid range: first(%d) > last(%d)", first, last)
    end
    return {
        first = first,
        last = last,
    }
end

M.WHOLE = { first = nil, last = nil }

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
    return new(math.min(prev.first, next.first), math.max(prev.last, next.last))
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@return Range
function M:get_range()
    return self.range or self
end

---@param first0 integer
---@param last0 integer
---@return Range
function M.from_vim(first0, last0)
    return new(first0 + 1, last0)
end

---@param first integer
---@param last integer
---@return Range
function M.from_lua(first, last)
    return new(first, last)
end

---@return boolean
function M:is_empty()
    return self.first > self.last
end

---@return string
function M:short()
    return string.format("(%d,%d)", self.first, self.last)
end

---@param self Range|nil
---@param target Range|nil
---@return boolean
function M:intersect(target)
    if not self or not target then
        return false
    end
    if self.last < target.first then
        return false
    end
    if target.last < self.first then
        return false
    end
    return true
end

---@param self Range
---@param index integer
---@return boolean
function M:contain(index)
    return self.first <= index and index <= self.last
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
        local merged = union_range(unions[#unions], ranges[index])
        if merged then
            unions[#unions] = merged
        else
            unions[#unions + 1] = ranges[index]
        end
    end
    return unions
end

---@param ranges Range[]
---@return Range
function M.join(ranges)
    local min = ranges[1].first
    local max = ranges[1].last
    for _, ranges in ipairs(ranges) do
        min = math.min(min, ranges.first)
        max = math.max(max, ranges.last)
    end
    return new(min, max)
end

---@param self Range
---@return integer
---@return integer
function M:to_vim()
    if M.is_whole(self) then
        return 0, api.nvim_buf_line_count(0)
    end
    return self.first - 1, self.last
end

---@param self Range
---@return integer
---@return integer
function M:to_lua()
    if M.is_whole(self) then
        return 1, api.nvim_buf_line_count(0)
    end
    return self.first, self.last
end

function M:is_whole()
    return not self.first or not self.last
end

---@param self Range
---@param first integer
function M:move_to(first)
    local count = self.last - self.first + 1
    self.first = first
    self.last = first + count - 1
end

---@param self Range[]
---@param delta integer
function M:shift(delta)
    for _, range in ipairs(self) do
        range.first = range.first + delta
        range.last = range.last + delta
    end
end

---@generic T
---@param items T[]
---@param range Range
---@return T[]
---@return T[]
---@return T[]
function M.split(items, range)
    local range1 = M.from_lua(1, range.first - 1)
    local range2 = M.from_lua(range.last + 1, math.huge)
    return M.slice(items, range1), M.slice(items, range), M.slice(items, range2)
end

---@generic T
---@param items T[]
---@param range Range
---@return T[]
function M.slice(items, range)
    local new_items = {}
    if M.is_empty(range) then
        return new_items
    end
    for _, item in ipairs(items) do
        if M.intersect(M.get_range(item), range) then
            local new_item = vim.deepcopy(item)
            local item_range = M.get_range(new_item)
            item_range.first = math.max(item_range.first, range.first)
            item_range.last = math.min(item_range.last, range.last)
            new_items[#new_items + 1] = new_item
        end
    end
    return new_items
end

return M
