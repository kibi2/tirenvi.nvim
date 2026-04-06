local config = require("tirenvi.config")

local M = {}

-- constants / defaults
local fn = vim.fn
local padding = config.marks.padding
local escaped_padding = vim.pesc(padding)

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

---@param cells Cell[]
---@param ncol integer:w
function M.normalize(cells, ncol)
    for index = 1, ncol do
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
function M:fill_padding(target_width)
    if target_width == nil then
        return self
    end
    local width = display_width(self)
    local diff = target_width - width
    if diff <= 0 then
        return self
    end
    return self .. string.rep(padding, diff)
end

---@param self Cell
---@return string
function M:remove_padding()
    return (self:gsub(escaped_padding, ""))
end

return M
