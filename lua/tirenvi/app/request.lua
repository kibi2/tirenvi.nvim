-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Request
---@field range Range
---@field lines? string[]
---@field attrs? Attr[]
---@field no_undo? boolean

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param range Range
---@return Request
function M.from_range(range)
    return {
        range = range,
    }
end

---@param range Range
---@param lines string[]
---@param no_undo boolean|nil
---@return Request
function M.from_lines(range, lines, no_undo)
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

return M
