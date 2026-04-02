local CONST = require("tirenvi.constants")
local Cell = require("tirenvi.core.cell")
local tir_vim = require("tirenvi.core.tir_vim")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param line string
---@return Record_plain
local function plain_new(line)
    return { kind = CONST.KIND.PLAIN, line = line }
end

---@param cells Cell[]
---@return Record_grid
local function grid_new(cells)
    return { kind = CONST.KIND.GRID, row = cells or {} }
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param vi_line string
---@return Record_plain
function M.plain.new_from_vi_line(vi_line)
    return plain_new(vi_line)
end

---@param self Record_plain
---@return Record_grid
function M.plain:to_grid()
    return grid_new({ self.line })
end

---@param vi_line string
---@return Record_grid
function M.grid.new_from_vi_line(vi_line)
    vi_line = vi_line or ""
    local cells = tir_vim.get_cells(vi_line)
    return grid_new(cells)
end

---@param self Record_grid
---@param columns Attr_column
function M.grid:pad_cells(columns)
    for icol, cell in ipairs(self.row) do
        self.row[icol] = Cell.pad_cell(cell, columns[icol].width)
    end
end

return M
