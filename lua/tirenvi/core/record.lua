local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local Cell = require("tirenvi.core.cell")
local tir_vim = require("tirenvi.core.tir_vim")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults
local pipec = config.marks.pipec
local pipen = config.marks.pipe

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param vi_line string
---@return Record
function M.from_vi_line(vi_line)
    local pipe = tir_vim.get_pipe_char(vi_line)
    if pipe then
        return M.grid.new_from_vi_line(vi_line, pipe == pipec)
    else
        return M.plain.new_from_vi_line(vi_line)
    end
end

---@param self Record_grid
---@param ncol integer
function M:apply_column_count(ncol)
    self.row = self.row or {}
    Cell.normalize(self.row, ncol)
    self.row = Cell.merge_tail(self.row, ncol)
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

---@param self Record_plain
function M.plain:remove_padding()
    self.line = Cell.remove_padding(self.line)
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
---@param columns Attr_column[]
---@return Record_grid[]
function M.grid:wrap(columns)
    local records = {}
    for icol, cell in ipairs(self.row) do
        local cells = Cell.wrap(cell, columns[icol].width, self._has_continuation)
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

---@param records Record_grid[]
---@return integer
function M.get_max_col(records)
    local max_col = 0
    for _, record in ipairs(records) do
        max_col = math.max(max_col, #record.row)
    end
    return max_col
end

---@param vi_lines string[]
---@return Record[]
function M.from_tir_vim(vi_lines)
    local records = {}
    for index = 1, #vi_lines do
        records[index] = M.from_vi_line(vi_lines[index])
    end
    return records
end

---@param ndjsons Ndjson[]
---@return string[]
function M.to_tir_vim(ndjsons)
    local tir_vim = {}
    for _, record in ipairs(ndjsons) do
        local kind = record.kind
        if kind == CONST.KIND.PLAIN then
            tir_vim[#tir_vim + 1] = record.line or ""
        elseif kind == CONST.KIND.GRID then
            local pipe = record._has_continuation and pipec or pipen
            local row_items = record.row
            local row = table.concat(row_items, pipe)
            row = pipe .. row .. pipe
            tir_vim[#tir_vim + 1] = row
        end
    end
    return tir_vim
end

return M
