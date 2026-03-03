local config = require("tirenvi.config")

local M = {}

-- constants / defaults
local fn = vim.fn
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param self Cell
---@return integer
local function display_width(self)
    if not self:find("[\t\128-\255]") then
        return #self
    end
    return fn.strdisplaywidth(self)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param cells Cell[]
---@return integer[]
function M.get_widths(cells)
    local widths = {}
    for _, cell in ipairs(cells) do
        local width = display_width(cell)
        widths[#widths + 1] = width
    end
    return widths
end

function M.normalize(cells)
    for index = 1, #cells do
        local cell = cells[index]
        if cell == nil then
            cells[index] = ""
        elseif type(cell) == "string" then
            -- do nothing
        else
            cells[index] = tostring(cell)
        end
    end
end

---@param self Cell
---@param target_width integer
---@return string
function M:pad_cell(target_width)
    if target_width == nil then
        return self
    end
    local width = display_width(self)
    local diff = target_width - width
    if diff <= 0 then
        return self
    end
    return self .. string.rep(config.marks.padding, diff)
end

return M
