local CONST = require("tirenvi.constants")
local Record = require("tirenvi.core.record")
local Cell = require("tirenvi.core.cell")
local config = require("tirenvi.config")
local Attr = require("tirenvi.core.attr")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function nop(...) end

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
    ---@type Ndjson[]
    local ndjsons = {}
    for _, record in ipairs(self.records) do
        ndjsons[#ndjsons + 1] = record
    end
    return ndjsons
end

---@param self Block_grid
local function split_lf(self)
    local records = {}
    for _, record in ipairs(self.records) do
        util.extend(records, Record.grid.split_lf(record))
    end
    self.records = records
end

---@param self Block_grid
local function fill_padding(self)
    for _, record in ipairs(self.records) do
        Record.grid.fill_padding(record, self.attr.columns)
    end
end

---@self Block_grid
local function remove_padding(self)
    for _, record in ipairs(self.records) do
        Record.grid.remove_padding(record)
    end
end

---@self Block_grid
local function concat_record(self)
    local records = {}
    ---@type Record_grid
    local new_record = nil
    local cont = false
    for _, record in ipairs(self.records) do
        if not cont then
            new_record = Record.grid.new(record.row)
            records[#records + 1] = new_record
        else
            Record.grid.concat(new_record, record)
        end
        cont = record._has_continuation
    end
    self.records = records
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@return Block
function M.new()
    return { attr = Attr.new(), records = {} }
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

---@self Block
function M:reset_attr()
    self.attr = Attr.new()
end

function M.plain.new()
    local self = M.new()
    M.set_kind(self, CONST.KIND.PLAIN)
    M.add(self, Record.plain.new_from_vi_line(""))
    return self
end

---@self Block_plain
---@return Ndjson[]
function M.plain:serialize()
    return serialize_records(self)
end

M.plain.normalize = nop
M.plain.to_vim = nop
M.plain.apply_replacements = nop
M.plain.from_vim = nop
M.plain.set_attr = nop
M.plain.set_attr_from_vi = nop

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
---@return Ndjson[]
function M.grid:serialize()
    return serialize_records(self)
end

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:normalize()
    reset_master_attr(self)
    local ncol = #self.attr.columns
    for _, record in ipairs(self.records) do
        Record.normalize_and_resize(record, ncol)
    end
end

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:to_vim()
    split_lf(self)
    fill_padding(self)
end

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

---@self Block_grid
function M.grid:from_vim()
    remove_padding(self)
    concat_record(self)
end

---@self Block_grid
---@return Block_grid
function M.grid:to_grid()
    return self
end

---@self Block
---@param attr Attr|nil
function M.grid:set_attr(attr)
    if not attr or Attr.is_plain(attr) then
        return
    end
    self.attr = attr
end

---@self Block
function M.grid:set_attr_from_vi()
    if #self.records == 0 then
        return
    end
    self.attr = Attr.grid.new_from_record(self.records[1])
end

return M
