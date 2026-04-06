local CONST = require("tirenvi.constants")
local Cell = require("tirenvi.core.cell")
local tir_vim = require("tirenvi.core.tir_vim")
local config = require("tirenvi.config")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param self Record_grid
---@param ncol integer
function M:apply_column_count(ncol)
    self.row = self.row or {}
    Cell.normalize(self.row, ncol)
    self.row = Cell.merge_tail(self.row, ncol) -- TODO join
end

---@param vi_line string
---@return Record_plain
function M.plain.new_from_vi_line(vi_line)
    return { kind = CONST.KIND.PLAIN, line = vi_line }
end

---@param self Record_plain
---@return Record_grid
function M.plain:to_grid()
    return M.grid.new({ self.line })
end

---@param cells Cell[]|nil
---@return Record_grid
function M.grid.new(cells)
    return { kind = CONST.KIND.GRID, row = cells or {} }
end

---@param vi_line string
---@param has_continuation boolean
---@return Record_grid
function M.grid.new_from_vi_line(vi_line, has_continuation)
    vi_line = vi_line or ""
    local cells = tir_vim.get_cells(vi_line)
    local record = M.grid.new(cells)
    record._has_continuation = has_continuation
    return record
end

---@param self Record_grid
---@param columns Attr_column
function M.grid:fill_padding(columns)
    for icol, cell in ipairs(self.row) do
        self.row[icol] = Cell.fill_padding(cell, columns[icol].width)
    end
end

---@param self Record_grid
function M.grid:remove_padding()
    for icol, cell in ipairs(self.row) do
        self.row[icol] = Cell.remove_padding(cell)
    end
end

---@param self Record_grid
---@return Record_grid[]
function M.grid:wrap_lf()
    local records = {}
    for icol, cell in ipairs(self.row) do
        local cells = Cell.wrap_lf(cell, self._has_continuation)
        for irow, cell in ipairs(cells) do
            records[irow] = records[irow] or M.grid.new()
            records[irow].row[icol] = cell
        end
    end
    local ncol = #self.row
    for irow = 1, #records do
        records[irow]._has_continuation = true
        Cell.normalize(records[irow].row, ncol)
    end
    records[#records]._has_continuation = self._has_continuation
    return records
end

---@param self Record_grid
---@param columns Attr_column[]
---@return Record_grid[]
function M.grid:wrap_width(columns)
    local records = {}
    for icol, cell in ipairs(self.row) do
        local cells = Cell.wrap_width(cell, columns[icol].width)
        for irow, cell in ipairs(cells) do
            records[irow] = records[irow] or M.grid.new()
            records[irow].row[icol] = cell
        end
    end
    local ncol = #self.row
    for irow = 1, #records do
        records[irow]._has_continuation = true
        Cell.normalize(records[irow].row, ncol)
    end
    records[#records]._has_continuation = self._has_continuation
    return records
end

---@param self Record_grid
---@param record Record_grid
function M.grid:concat(record)
    for icol, cell in ipairs(self.row) do
        self.row[icol] = cell .. record.row[icol]
    end
end

return M
