---@class WidthModeState
---@field mode '"fit"'|'"max"'|'"auto"'|'"fix"'
---@field kind string
---@field number number[]

local log = require("tirenvi.util.log")

local M   = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param mode WidthMode
---@param number number[]|nil
---@return WidthModeState
function M.new(mode, kind, number)
    assert(mode == "auto" or mode == "fit" or mode == "max" or mode == "fix")
    local self = { mode = mode, kind = kind }
    self.number = number or {}
    return self
end

return M
