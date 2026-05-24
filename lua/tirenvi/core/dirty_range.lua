local tir_text = require("tirenvi.core.tir_text")
local Range3 = require("tirenvi.util.range3")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param line_provider LineProvider
---@param range Range
local function expand_continue_lines(line_provider, range)
    local first, last = Range.to_lua(range)
    local lines = line_provider.get_lines(first, last)
    local prev = range.first - 1
    local prev_line = line_provider.get_line(prev)
    while tir_text.is_continue_line(prev_line) do
        prev = prev - 1
        prev_line = line_provider.get_line(prev)
    end
    range.first = prev + 1
    ---@type string|nil
    local last_line = lines[#lines]
    local last = range.last
    while tir_text.is_continue_line(last_line) or last_line == "" do
        last = last + 1
        last_line = line_provider.get_line(last)
    end
    range.last = last
end

---@param line_provider LineProvider
---@param range3 Range3
---@return Range
local function get_new_range(line_provider, range3)
    local new_range = Range3.get_new_range(range3)
    log.watch("INVD", new_range)
    expand_continue_lines(line_provider, new_range)
    return new_range
end

---@param line_provider LineProvider
---@param prev_ranges Range[]
---@param range3 Range3
---@return Range[]
local function adjust(line_provider, prev_ranges, range3)
    local ranges1, _, ranges3 = Range.split(prev_ranges, Range.from_lua(range3.first, range3.last))
    Range.shift(ranges3, Range3.get_delta(range3))
    local range2 = get_new_range(line_provider, range3)
    local new_ranges = ranges1
    new_ranges[#new_ranges + 1] = range2
    util.extend(new_ranges, ranges3)
    return Range.union(new_ranges)
end

---@param line_provider LineProvider
---@param new_ranges Range[]
---@return Range[]
local function check_invalid(line_provider, new_ranges)
    local inv_ranges = {}
    for _, range in ipairs(new_ranges) do
        for irow = range.first, range.last do
            inv_ranges[#inv_ranges + 1] = Range.from_lua(irow, irow)
        end
    end
    Range.union(inv_ranges)
    return inv_ranges
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param line_provider LineProvider
---@param range3 Range3
---@return Range[]
function M.reconcile(line_provider, prev_ranges, range3)
    local new_ranges = adjust(line_provider, prev_ranges, range3)
    local inv_ranges = check_invalid(line_provider, new_ranges)
    -- local inv_ranges = new_ranges
    return inv_ranges
end

return M
