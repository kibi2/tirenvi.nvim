-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Request
---@field context Context
---@field range? Range
---@field lines? string[]
---@field no_undo? boolean

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param context Context
---@param range Range
---@return Request
function M.from_range(context, range)
    return {
        context = context,
        range = range,
    }
end

---@param context Context
---@param range Range
---@param lines string[]
---@param no_undo boolean|nil
---@return Request
function M.from_lines(context, range, lines, no_undo)
    return {
        context = context,
        range = range,
        lines = lines,
        no_undo = no_undo or false,
    }
end

return M
