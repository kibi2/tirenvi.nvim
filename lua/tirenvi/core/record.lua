local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local Cell = require("tirenvi.core.cell")
local Bufline = require("tirenvi.parser.bufline")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param bufline string
---@param embedded_key string|nil
---@return Record
local function from_bufline(bufline, embedded_key)
    local pipe = Bufline.get_pipe_char(bufline)
    if pipe then
        return M.grid.new_from_bufline(bufline, pipe, embedded_key)
    else
        return M.plain.new_from_bufline(bufline)
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param self Record_grid
---@param ncol integer
function M:apply_column_count(ncol)
    self.row = self.row or {}
    Cell.normalize(self.row, ncol)
    self.row = Cell.merge_tail(self.row, ncol)
end

---@param bufline string
---@return Record_plain
function M.plain.new_from_bufline(bufline)
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

---@param bufline string
---@param pipe string
---@param embedded_key string|nil
---@return Record_grid
function M.grid.new_from_bufline(bufline, pipe, embedded_key)
    local pos = string.find(bufline, pipe, 1, true) or 1
    local prefix = string.sub(bufline, 1, pos - 1)
    if vim.trim(prefix) == embedded_key then
        bufline = string.sub(bufline, pos)
    end
    local cells = Bufline.get_cells(bufline)
    local record = M.grid.new(cells)
    if vim.trim(prefix) == embedded_key then
        record.prefix = prefix
    end
    record._has_continuation = pipe == config.marks.pipec
    return record
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

---@param buflines string[]
---@param embedded_key string|nil
---@return Record[]
function M.from_buflines(buflines, embedded_key)
    local records = {}
    for index = 1, #buflines do
        records[index] = from_bufline(buflines[index], embedded_key)
    end
    return records
end

---@param records Record[]
---@return string[]
function M.to_buflines(records)
    local pipec = config.marks.pipec
    local pipen = config.marks.pipe
    local buflines = {}
    for _, record in ipairs(records) do
        local kind = record.kind
        if kind == CONST.KIND.PLAIN then
            buflines[#buflines + 1] = record.line or ""
        elseif kind == CONST.KIND.GRID then
            local pipe = record._has_continuation and pipec or pipen
            local row_items = record.row
            local row = table.concat(row_items, pipe)
            row = pipe .. row .. pipe
            local line = (record.prefix or "") .. row
            buflines[#buflines + 1] = line
        end
    end
    return buflines
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
