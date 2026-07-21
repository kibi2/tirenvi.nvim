local CONST = require("tirenvi.constants") -- Root

local Cell = require("tirenvi.core.cell")  -- Core

local log = require("tirenvi.util.log")    -- Util


-- =============================================================================

local M = {}
M.plain = {}
M.grid = {}

-- =============================================================================
-- Public API

---@param self Record_grid
---@param ncol integer
function M:apply_column_count(ncol)
    self.row = self.row or {}
    Cell.normalize(self.row, ncol)
    self.row = Cell.merge_tail(self.row, ncol)
end

---@param bufline string
---@return Record_plain
function M.plain.new(bufline)
    return { kind = CONST.KIND.PLAIN, line = bufline }
end

---@param self Record_plain
---@return Record
function M.plain:change_kind(kind)
    if kind == CONST.KIND.PLAIN then
        return self
    else
        return M.plain.to_grid(self)
    end
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

---@param self Record_grid
---@return Record
function M.grid:change_kind(kind)
    if kind == CONST.KIND.PLAIN then
        return { kind = CONST.KIND.PLAIN, line = table.concat(self.row, " ") }
    else
        return self
    end
end

---@param self Record_grid
---@return Record_grid
function M.grid:to_grid()
    return self
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
            records[irow].prefix = self.prefix
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
function M.get_max_ncol(records)
    local max_col = 0
    for _, record in ipairs(records) do
        max_col = math.max(max_col, #record.row)
    end
    return max_col
end

---@param self Record_grid[]
---@return integer|nil
function M.get_consistent_ncol(self)
    local ncol = #self[1].row
    for irecord = 2, #self do
        if ncol ~= #self[irecord].row then
            return nil
        end
    end
    return ncol
end

return M
