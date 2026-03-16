local CONST = require("tirenvi.constants")
local Record = require("tirenvi.core.record")
local Cell = require("tirenvi.core.cell")
local config = require("tirenvi.config")
local Attr = require("tirenvi.core.attr")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function nop(...) end

---@param record Record_grid
---@param new_count integer
---@return nil
local function increase_cols(record, new_count)
    local row = record.row
    for _ = #row + 1, new_count do
        row[#row + 1] = ""
    end
end

---@param record Record_grid
---@param new_count integer
---@return nil
local function decrease_cols(record, new_count)
    local row = record.row
    row[new_count] = table.concat(row, " ", new_count)
    for i = #row, new_count + 1, -1 do
        row[i] = nil
    end
end

---@param record Record_grid
---@param ncol integer
local function resize_columns(record, ncol)
    local old_count = #record.row
    if old_count > ncol then
        decrease_cols(record, ncol)
    elseif old_count < ncol then
        increase_cols(record, ncol)
    end
end

---@param record Record_grid
local function normalize_row(record)
    record.row = record.row or {}
    Cell.normalize(record.row)
end

---@param record Record_grid
---@param ncol integer
local function normalize_and_resize(record, ncol)
    normalize_row(record)
    resize_columns(record, ncol)
end

---@self Block_grid
local function reset_master_attr(self)
    if Attr.grid.has_all(self.attr) then
        return
    end
    Attr.grid.extend(self.attr, self.records)
end

---@self Block
---@param kind Block_kind
local function initialize(self, kind)
    self.kind = kind
    self.attr = Attr[self.kind].new()
end

---@param self Block
---@return Ndjson[]
local function serialize_records(self)
    local ndjsons = {}
    for i, record in ipairs(self.records) do
        ndjsons[i] = record
    end
    return ndjsons
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@return Block
function M.new()
    return { records = {} }
end

---@self Block
---@param kind Block_kind
function M:set_kind(kind)
    if self.kind == kind then
        return
    end
    assert(not self.kind, "Block kind already set")
    initialize(self, kind)
end

---@self Block
---@param record Record
function M:add(record)
    self.records[#self.records + 1] = record
end

M.plain.serialize = serialize_records
M.grid.serialize = serialize_records

M.plain.normalize = nop

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:normalize()
    reset_master_attr(self)
    local ncol = #self.attr.columns
    for _, record in ipairs(self.records) do
        normalize_and_resize(record, ncol)
    end
end

M.plain.to_vim = nop

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:to_vim()
    for _, record in ipairs(self.records) do
        Record.grid.pad_cells(record, self.attr.columns)
    end
end

M.plain.apply_replacements = nop

---@self Block_grid
---@param replace {[string]:string}
function M.grid:apply_replacements(replace)
    for _, record in ipairs(self.records) do
        assert(record.kind == CONST.KIND.GRID, "unexpected record kind")
        for icol, cell in ipairs(record.row) do
            for key, val in pairs(replace) do
                cell = cell:gsub(key, val)
            end
            record.row[icol] = cell
        end
    end
end

M.plain.remove_padding = nop

---@self Block_grid
function M.grid:remove_padding()
    local escaped_padding = vim.pesc(config.marks.padding)
    for _, record in ipairs(self.records) do
        assert(record.kind == CONST.KIND.GRID)
        for icol, cell in ipairs(record.row) do
            cell = cell:gsub(escaped_padding, "")
            record.row[icol] = cell
        end
    end
end

---@self Block_plain
---@param attr Attr_plain
function M.plain:set_attr_if_empty(attr)
    self.attr = attr
end

---@self Block_grid
---@param attr Attr_grid
function M.grid:set_attr_if_empty(attr)
    if Attr.is_empty(self.attr) then
        self.attr = attr
    end
end

---@self Block_plain
---@return Block_grid
function M.plain:to_grid()
    local block = M.new()
    M.set_kind(block, CONST.KIND.GRID)
    for index, record in ipairs(self.records) do
        block.records[index] = Record.plain.to_grid(record)
    end
    ---@cast block Block_grid
    return block
end

---@self Block_grid
---@return Block_grid
function M.grid:to_grid()
    return self
end

return M
