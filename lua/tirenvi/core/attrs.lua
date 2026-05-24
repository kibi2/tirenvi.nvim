local Attr  = require("tirenvi.core.attr")
local Range = require("tirenvi.util.range")
local util  = require("tirenvi.util.util")
local log   = require("tirenvi.util.log")

local M     = {}
local api   = vim.api

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param self Attr[]
---@return Attr[]
local function connect(self)
    local attrs = { self[1] }
    for iattr = 2, #self do
        local attr = self[iattr]
        if Attr.is_same_columns(attrs[#attrs], attr) then
            attrs[#attrs].range.last = attr.range.last
        else
            attrs[#attrs + 1] = attr
        end
    end
    return attrs
end

---@param self Attr[]
local function reset_range(self)
    local last = self[1].range.last
    for iattr = 2, #self do
        local range = self[iattr].range
        Range.move_to(range, last + 1)
        last = range.last
    end
end

---@param seq integer
---@param range3 Range3
---@param size integer
---@param new_size integer
local function get_new_seq(seq, range3, size, new_size)
    local pos = seq - range3.first
    local new_pos = pos
    if 0 <= pos and pos < size then
        new_pos = pos * new_size / size
    elseif size <= pos then
        new_pos = pos + new_size - size
    end
    return new_pos + range3.first
end

local current_index = 1
---@param self Attr[]
---@param irow integer
---@return integer|nil
local function get_index(self, irow)
    if current_index > #self then
        current_index = 1
    end
    for _ = 1, #self do
        if Range.contain(self[current_index].range, irow) then
            return current_index
        end
        current_index = current_index % #self + 1
    end
    return nil
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param self Attr[]
---@return boolean
function M.has_range(self)
    if not self then
        return false
    end
    for _, attr in ipairs(self) do
        if attr.range == nil then
            return false
        end
    end
    return true
end

---@param self Attr[]|nil
---@return Attr[]
function M.get_grid_attrs(self)
    self = self or {}
    local attrs = {}
    for _, attr in ipairs(self) do
        if Attr.is_grid(attr) then
            attrs[#attrs + 1] = attr
        end
    end
    return attrs
end

---@param self Attr[]
---@param range Range
---@param doc_attrs Attr[]
---@return Attr[]
function M:replace_attrs(range, doc_attrs)
    local attrs1, _, attrs3 = Range.split(self, range)
    local attrs = attrs1
    log.watch("ATTR", range)
    log.watch("ATTR", M.debug_attrs(self, "MERGE ORIGIN:"))
    log.watch("ATTR", M.debug_attrs(attrs1, "MERGE:") ..
        M.debug_attrs(doc_attrs, " + ") ..
        M.debug_attrs(attrs3, " + "))
    util.extend(attrs, doc_attrs)
    util.extend(attrs, attrs3)
    attrs = connect(attrs)
    reset_range(attrs)
    return attrs
end

local nmax = 4

---@param self Attr[]
---@param title string
---@return string
function M:debug_attrs(title)
    if not log.is_debug() then
        return ""
    end
    if not self then
        return title .. "nil"
    end
    local strings = { title }
    for iattr = 1, math.min(#self, nmax) do
        strings[#strings + 1] = Attr.get_attr_long(self[iattr])
    end
    return table.concat(strings, " ")
end

---@param self Attr[]
function M:remove_range()
    for _, attr in ipairs(self) do
        attr.range = nil
    end
end

---@param attrs Attr[]
---@param range3 Range3|nil
---@return Attr[]
function M.adjust(attrs, range3)
    if #attrs == 0 or not range3 then
        return attrs
    end
    if not attrs[1].range then
        return attrs
    end
    local size = range3.last - range3.first + 1
    local new_size = range3.new_last - range3.first + 1
    for _, attr in ipairs(attrs) do
        attr.range.first = get_new_seq(attr.range.first, range3, size, new_size)
        attr.range.last = get_new_seq(attr.range.last, range3, size, new_size)
    end
    log.watch("ATTR", M.debug_attrs(attrs, "UPDATE RANGE expand 1:"))
    for iattr = 1, #attrs - 1 do
        attrs[iattr].range.last = attrs[iattr + 1].range.first - 1
    end
    attrs[1].range.first = 1
    attrs[#attrs].range.last = api.nvim_buf_line_count(0)
    log.watch("ATTR", M.debug_attrs(attrs, "UPDATE RANGE expand 2:"))
    local new_attrs = {}
    for _, attr in ipairs(attrs) do
        if attr.range.first <= attr.range.last then
            new_attrs[#new_attrs + 1] = attr
        end
    end
    return new_attrs
end

---@param self Attr[]
---@param range Range
---@return Attr|nil
function M.get_attr(self, range)
    for _, attr in ipairs(self) do
        if Range.intersect(attr.range, range) then
            return attr
        end
    end
    return nil
end

---@param self Attr[]
---@param irow integer
---@return Attr|nil
function M:get(irow)
    return self[get_index(self, irow)]
end

return M
