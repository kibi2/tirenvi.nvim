local CONST = require("tirenvi.constants")
local Cell = require("tirenvi.core.cell")
local tir_vim = require("tirenvi.core.tir_vim")
local config = require("tirenvi.config")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults
local lf = config.marks.lf

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param line string
---@return Record_plain
local function plain_new(line)
    return { kind = CONST.KIND.PLAIN, line = line }
end

---@param self Record_grid
---@param new_count integer
---@return nil
local function decrease_cols(self, new_count)
    local row = self.row
    row[new_count] = table.concat(row, " ", new_count)
    for i = #row, new_count + 1, -1 do
        row[i] = nil
    end
end

---@param self Record_grid
---@param ncol integer
local function resize_columns(self, ncol)
    local old_count = #self.row
    if old_count > ncol then
        decrease_cols(self, ncol)
    end
end

---@param self Record_grid
local function normalize_row(self, ncol)
    self.row = self.row or {}
    Cell.normalize(self.row, ncol)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param cells Cell[]|nil
---@return Record_grid
function M.grid.new(cells)
    return { kind = CONST.KIND.GRID, row = cells or {} }
end

---@param vi_line string
---@return Record_plain
function M.plain.new_from_vi_line(vi_line)
    return plain_new(vi_line)
end

---@param self Record_grid
---@param ncol integer
function M:normalize_and_resize(ncol)
    normalize_row(self, ncol)
    resize_columns(self, ncol)
end

---@param self Record_plain
---@return Record_grid
function M.plain:to_grid()
    return M.grid.new({ self.line })
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

local multiline_lf = true

---@param self Record_grid
---@return Record_grid[]
function M.grid:split_lf()
    local records = {}
    local nrow = 0
    for icol, cell in ipairs(self.row) do
        local cells = { cell }
        if multiline_lf then
            cells = vim.split(cell, lf)
            if #cells > 1 and cells[#cells] == "" and self._has_continuation then
                cells[#cells] = nil
            end
        end
        for irow, cell in ipairs(cells) do
            records[irow] = records[irow] or M.grid.new()
            local append = irow ~= #cells and lf or ""
            records[irow].row[icol] = cell .. append
        end
        nrow = math.max(nrow, #cells)
    end
    local ncol = #self.row
    for irow = 1, nrow do
        records[irow]._has_continuation = true
        normalize_row(records[irow], ncol)
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
