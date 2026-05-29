-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Request
---@field range Range
---@field lines string[]
---@field attrs Attr[]
---@field no_undo boolean

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param range Range
---@return Request
function M.new_reader(range)
    local self = {
        range = range,
    }
    return self
end

---@param range Range
---@param lines string[]
---@param no_undo boolean|nil
---@return Request
function M.new_writer(range, lines, no_undo)
    return {
        range = range,
        lines = lines,
        no_undo = no_undo or false,
    }
end

---@param self Request
---@return integer -- 1-based
---@return integer -- 1-based
function M:lua_range()
    return Range.to_lua(self.range)
end

---@param self Request
---@return Range3
function M:get_range3()
    local first, last = M.lua_range(self)
    return Range3.new(first, last, first + #self.lines - 1)
end

---@param self Request
---@return boolean
function M:is_no_undo()
    return self.no_undo == true
end

return M
