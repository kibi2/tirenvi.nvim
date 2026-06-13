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
---@param pages integer|nil
---@param width integer|nil
---@return WidthModeState
function M.new(mode, pages, width)
    assert(mode == "auto" or mode == "fit" or mode == "max" or mode == "fix")
    return { mode = mode, pages = pages, width = width }
end

return M
