local config = require("tirenvi.config")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults
local fn = vim.fn
local padding = config.marks.padding
local escaped_padding = vim.pesc(padding)
local lf = config.marks.lf

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

local lf_len = display_width(lf)

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

---@param self Cell
---@return integer
function M.get_width(self)
    if not self then
        return 0
    end
    local cells = vim.split(self, lf)
    local max_width = 0
    for icell, cell in pairs(cells) do
        local width = display_width(cell)
        if icell ~= #cells then
            width = width + lf_len
        end
        max_width = math.max(max_width, width)
    end
    return max_width
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

---@param cells string[]
---@param ncol integer
---@return string[][]
local function to_2d(cells, ncol)
    local width = ncol + 1
    local result = {}
    local row = {}
    for _, cell in ipairs(cells) do
        table.insert(row, cell)
        if #row == width then
            table.insert(result, row)
            row = {}
        end
    end
    if #row > 0 then
        table.insert(result, row)
    end
    return result
end

local function get_delim_from_cell(cell)
    if cell == "" then
        return ""
    elseif cell:match("^ +$") then
        return " "
    else
        return nil
    end
end

---@param cell2d string[][]
---@return string|nil
local function get_delim(cell2d)
    local ncol = #cell2d[1] - 1
    local ncolp1 = ncol + 1
    if #cell2d[#cell2d] ~= ncol then
        return nil
    end
    local delm = get_delim_from_cell(cell2d[1][ncolp1])
    for irow = 2, #cell2d - 1 do
        if delm ~= get_delim_from_cell(cell2d[irow][ncolp1]) then
            return nil
        end
    end
    return delm
end

---@param cells Cell[]
---@param ncol integer
---@return Cell[]|nil
local function join(cells, ncol)
    local cells2d = to_2d(cells, ncol)
    local delim = get_delim(cells2d)
    if not delim then
        return nil
    end
    local join_row = vim.list_slice(cells2d[1], 1, ncol)
    for irow = 2, #cells2d do
        for icol = 1, ncol do
            join_row[icol] = join_row[icol] .. delim .. cells2d[irow][icol]
        end
    end
    return join_row
end

---@param cells Cell[]
---@param ncol integer
---@return Cell[]
function M.merge_tail(cells, ncol)
    if #cells <= ncol then
        return cells
    end
    local join_cells = join(cells, ncol)
    if join_cells then
        return join_cells
    else
        cells[ncol] = table.concat(cells, " ", ncol)
        return vim.list_slice(cells, 1, ncol)
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

---@param self Cell
---@param width integer
---@param _has_continuation boolean
---@return Cell[]
function M:wrap(width, _has_continuation)
    local cells = {}
    if not self or self == "" or width <= 0 then
        return { self }
    end
    local chars = util.utf8_chars(self)
    local current = ""
    local current_width = 0
    for _, char in ipairs(chars) do
        local ch_width = display_width(char)
        if current ~= "" and current_width + ch_width > width then
            cells[#cells + 1] = current
            current = char
            current_width = ch_width
        else
            current = current .. char
            current_width = current_width + ch_width
        end
        if char == lf then
            cells[#cells + 1] = current
            current = ""
            current_width = 0
        end
    end
    if not (current == "" and _has_continuation) then
        cells[#cells + 1] = current
    end
    return cells
end

return M
