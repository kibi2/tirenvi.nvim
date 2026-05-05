-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Document = require("tirenvi.core.document")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Request
---@field range? Range
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
---@param document Document|nil
---@param no_undo boolean|nil
---@return Request
function M.from_lines(range, lines, document, no_undo)
    local self = {
        range = range,
        lines = lines,
        no_undo = no_undo or false,
    }
    self.attrs = Document.collect_attrs(document)
    return self
end

return M
