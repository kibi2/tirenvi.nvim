local Attr = require("tirenvi.core.attr")
local Attrs = require("tirenvi.core.attrs")
local tir_buf = require("tirenvi.core.tir_buf")
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
    while tir_buf.is_continue_line(prev_line) do
        prev = prev - 1
        prev_line = line_provider.get_line(prev)
    end
    range.first = prev + 1
    ---@type string|nil
    local last_line = lines[#lines]
    local last = range.last
    while tir_buf.is_continue_line(last_line) do
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
    return Range.merge(new_ranges)
end

---@param attr Attr|nil
---@param line string|nil
---@return boolean
local function is_valid(attr, line)
    if not line then
        return true
    end
    if not attr then
        return false
    end
    local pipe = tir_buf.get_pipe_char(line)
    if not pipe then
        return Attr.is_plain(attr)
    end
    if not tir_buf.is_normal_grid(line, pipe) then
        return false
    end
    local widths = tir_buf.get_widths(line)
    if #attr.columns ~= #widths then
        return false
    end
    for icol, width in ipairs(widths) do
        if attr.columns[icol].width ~= width then
            return false
        end
    end
    return true
end

---@param line_provider LineProvider
---@param new_ranges Range[]
---@param attrs Attr[]
---@return Range[]
local function check_dirty(line_provider, new_ranges, attrs)
    local inv_ranges = {}
    for _, range in ipairs(new_ranges) do
        for irow = range.first, range.last do
            local attr = Attrs.get(attrs, irow)
            local line = line_provider.get_line(irow)
            if not is_valid(attr, line) then
                Range.push(inv_ranges, irow)
            end
        end
    end
    return inv_ranges
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param line_provider LineProvider
---@param prev_ranges Range[]
---@param attrs Attr[]
---@param range3 Range3
---@return Range[]
function M.reconcile(line_provider, prev_ranges, attrs, range3)
    local new_ranges = adjust(line_provider, prev_ranges, range3)
    local inv_ranges = check_dirty(line_provider, new_ranges, attrs)
    log.watch("INVD", inv_ranges)
    return inv_ranges
end

---@param prev_ranges Range[]
---@param range3 Range3
---@return Range[]
function M.remove(prev_ranges, range3)
    local ranges1, _, ranges3 = Range.split(prev_ranges, Range.from_lua(range3.first, range3.last))
    Range.shift(ranges3, Range3.get_delta(range3))
    local new_ranges = ranges1
    util.extend(new_ranges, ranges3)
    return Range.merge(new_ranges)
end

return M
