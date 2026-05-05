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
---@field start0 integer
---@field end0 integer
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
    local start0, end0 = range:to_vim()
    return {
        start0 = start0,
        end0 = end0,
    }
end

---@param start0 integer
---@param end0 integer
---@return Request
function M.from_vim0(start0, end0)
    return {
        start0 = start0,
        end0 = end0,
    }
end

---@param start0 integer
---@param end0 integer
---@param lines string[]
---@param document Document|nil
---@param no_undo boolean|nil
---@return Request
function M.from_lines(start0, end0, lines, document, no_undo)
    local self = {
        start0 = start0,
        end0 = end0,
        lines = lines,
        no_undo = no_undo or false,
    }
    self.attrs = Document.collect_attrs(document)
    return self
end

return M
