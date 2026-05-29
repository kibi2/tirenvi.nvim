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

---@class ReadResult
---@field range Range
---@field lines string[]
---@field attrs Attr[]|nil
---@field is_flat? boolean

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param range Range
---@return ReadResult
function M.new_reader(range)
    return {
        range = range,
    }
end

---@param self ReadResult
---@return integer -- 1-based
---@return integer -- 1-based
function M:lua_range()
    return Range.to_lua(self.range)
end

---@param self ReadResult
---@return boolean
function M:is_flat()
    return self.is_flat == true
end

return M
