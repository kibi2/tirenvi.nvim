---@class WidthModeState
---@field mode '"fit"'|'"max"'|'"auto"'|'"fix"'
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
function M.new(mode, number)
    assert(mode == "auto" or mode == "fit" or mode == "max" or mode == "fix")
    local self = { mode = mode }
    self.number = number or {}
    return self
end

return M
