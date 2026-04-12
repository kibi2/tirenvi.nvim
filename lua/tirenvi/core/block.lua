local CONST = require("tirenvi.constants")
local Record = require("tirenvi.core.record")
local config = require("tirenvi.config")
local Attr = require("tirenvi.core.attr")
local util = require("tirenvi.util.util")
local range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

---@param map {[string]: string}
---@return {[string]: string}
local function prepare_replace_map(map)
    local out = {}
    for key, value in pairs(map) do
        out[vim.pesc(key)] = value
    end
    return out
end

local ESCAPE_MAP = prepare_replace_map({
    ["\n"] = config.marks.lf,
    ["\t"] = config.marks.tab,
})

local UNESCAPE_MAP = prepare_replace_map({
    [config.marks.lf] = "\n",
    [config.marks.tab] = "\t",
})

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function nop(...) end

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
local function wrap_lf(self)
    local records = {}
    for _, record in ipairs(self.records) do
        util.extend(records, Record.grid.wrap_lf(record))
    end
    self.records = records
end

---@param self Block_grid
local function wrap_width(self)
    local records = {}
    for _, record in ipairs(self.records) do
        util.extend(records, Record.grid.wrap_width(record, self.attr.columns))
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
local function unwrap(self)
    local records = {}
    ---@type Record_grid
    local new_record = nil
    local cont_prev = false
    for _, record in ipairs(self.records) do
        if not cont_prev then
            new_record = Record.grid.new(record.row)
            records[#records + 1] = new_record
        else
            Record.grid.concat(new_record, record)
        end
        cont_prev = record._has_continuation
        new_record._has_continuation = cont_prev
    end
    self.records = records
end

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
local function apply_column_count(self, ncol)
    for _, record in ipairs(self.records) do
        Record.apply_column_count(record, ncol)
    end
end

---@self Block
local function ensure_table_attr(self)
    if #self.attr.columns == 0 then
        local ncol = Record.get_max_col(self.records)
        Attr.grid.new_max_width(self.attr, ncol, self.records)
    else
        Attr.grid.auto_width(self.attr, self.records)
    end
end

---@self Block
---@self Block_grid
---@param replace {[string]:string}
local function apply_replacements(self, replace)
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

---@param operator string
---@param count integer
---@param old_width integer
---@return integer|nil
local function get_new_width(operator, count, old_width)
    if operator == "=" then
        return count
    elseif operator == "+" then
        if count == 0 then
            count = 1
        end
        return old_width + count
    elseif operator == "-" then
        if count == 0 then
            count = 1
        end
        return old_width - count
    else
        return nil
    end
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

---@self Block_plain
---@return integer[]
function M.plain:get_widths()
    return {}
end

M.plain.set_widths = nop
M.plain.change_width = nop
M.plain.set_attr = nop
M.plain.from_flat = nop
M.plain.to_flat = nop
M.plain.from_vim = nop
M.plain.to_vim = nop

---@self Block_grid
---@return Ndjson[]
function M.grid:serialize()
    return serialize_records(self)
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

---@self Block_grid
---@return integer[]
function M.grid:get_widths()
    local widths = {}
    for _, column in ipairs(self.attr.columns) do
        widths[#widths + 1] = column.width
    end
    return widths
end

---@self Block_grid
function M.grid:set_widths(widths)
    Attr.set_widths(self.attr, widths)
end

---@self Block_grid
---@param operator string
---@param count integer
---@param col Range
local function change_width(attr, icol, start_col, operator, count, col)
    local column = attr.columns[icol]
    local old_width = column.width
    local cel_range = { first = start_col, last = start_col + old_width }
    if range.intersect(cel_range, col) then
        local new_width = get_new_width(operator, count, old_width)
        Attr.grid.set_width(attr, icol, new_width)
    end
end

---@self Block_grid
---@param operator string
---@param count integer
---@param col Range
function M.grid:change_width(operator, count, col)
    local start_col = 1
    for icol, column in ipairs(self.attr.columns) do
        local old_width = column.width
        change_width(self.attr, icol, start_col, operator, count, col)
        start_col = start_col + old_width + 1
    end
end

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:from_flat()
    local ncol = Record.get_max_col(self.records)
    apply_column_count(self, ncol)
    apply_replacements(self, ESCAPE_MAP)
end

---@self Block_grid
function M.grid:to_flat()
    apply_replacements(self, UNESCAPE_MAP)
end

---@self Block_grid
---@param no_unwrap boolean  -- If true, skip unwrapping.
-- Prevents line count changes that would break put(); used for repair.
function M.grid:from_vim(no_unwrap)
    ensure_table_attr(self)
    remove_padding(self)
    apply_column_count(self, #self.attr.columns)
    if not no_unwrap then
        unwrap(self)
    end
end

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:to_vim()
    wrap_lf(self)
    ensure_table_attr(self)
    apply_column_count(self, #self.attr.columns)
    wrap_width(self)
    fill_padding(self)
end

return M
