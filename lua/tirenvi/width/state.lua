---@class WidthModeState
---@field mode '"fit"'|'"max"'|'"auto"'|'"fix"'
---@field pages? integer
---@field width? integer

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
---@return WidthModeState
function M.new(mode)
    assert(mode == "auto" or mode == "fit" or mode == "max" or mode == "fix")
    local self = { mode = mode, count = 0, width = 0 }
    return self
end

return M
