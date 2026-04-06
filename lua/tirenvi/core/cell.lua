local config = require("tirenvi.config")
local util = require("tirenvi.util.util")

local M = {}

-- constants / defaults
local fn = vim.fn
local padding = config.marks.padding
local escaped_padding = vim.pesc(padding)
local lf = config.marks.lf

local multiline_lf = true

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
        elseif type(cell) ~= "string" then
            cells[index] = tostring(cell)
        end
    end
end

---@param cells Cell[]
---@param ncol integer
---@return Cell[]
function M.merge_tail(cells, ncol)
    if #cells <= ncol then
        return cells
    end
    cells[ncol] = table.concat(cells, " ", ncol)
    return vim.list_slice(cells, 1, ncol)
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

---@param self Cell
---@param _has_continuation boolean
---@return Cell[]
function M:wrap_lf(_has_continuation)
    if not multiline_lf then
        return { self }
    end
    local cells = vim.split(self, lf)
    for irow = 1, #cells - 1 do
        cells[irow] = cells[irow] .. lf
    end
    if #cells > 1 and cells[#cells] == "" and _has_continuation then
        cells[#cells] = nil
    end
    return cells
end

---@param self Cell
---@param width integer
---@return Cell[]
function M:wrap_width(width)
    local cells = {}

    -- 空やwidth不正はそのまま返す
    if not self or self == "" or width <= 0 then
        return { self }
    end

    local chars = util.utf8_chars(self)

    local current = ""
    local current_width = 0

    for _, ch in ipairs(chars) do
        local ch_width = display_width(ch)

        -- 追加すると幅オーバーする場合は確定
        if current ~= "" and current_width + ch_width > width then
            cells[#cells + 1] = current
            current = ch
            current_width = ch_width
        else
            current = current .. ch
            current_width = current_width + ch_width
        end
    end

    -- 残りを追加
    if current ~= "" then
        cells[#cells + 1] = current
    end

    return cells
end

return M
