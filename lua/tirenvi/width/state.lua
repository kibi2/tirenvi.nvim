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

---@param mode string
---@return WidthModeState
function M.new(mode)
    local self = { mode = mode, count = 0, width = 0 }
    return self
end

return M
