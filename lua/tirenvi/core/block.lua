local CONST = require("tirenvi.constants")
local Record = require("tirenvi.core.record")
local config = require("tirenvi.config")
local Attr = require("tirenvi.core.attr")
local Attrs = require("tirenvi.core.attrs")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}
M.plain = {}
M.grid = {}

-- constants / defaults

---@param self Block
---@param method string
---@param ... unknown
local function apply(self, method, ...)
    for _, record in ipairs(self.records) do
        local common = Record[method]
        if common then
            common(record, ...)
        end

        local handler = Record[record.kind]
        local specific = handler[method]
        if specific then
            specific(record, ...)
        end
    end
end

---@param map {[string]: string}
---@return {[string]: string}
local function prepare_replace_map(map)
    local out = {}
    for key, value in pairs(map) do
        out[vim.pesc(key)] = value
    end
    return out
end

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function nop(...) end

---@return {[string]: string}
local function get_escape_map()
    return prepare_replace_map({
        ["\n"] = config.marks.lf,
        ["\t"] = config.marks.tab,
    })
end

---@return {[string]: string}
local function get_un_escape_map()
    return prepare_replace_map({
        [config.marks.lf] = "\n",
        [config.marks.tab] = "\t",
    })
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
local function wrap(self)
    local records = {}
    for _, record in ipairs(self.records) do
        util.extend(records, Record.grid.wrap(record, self.attr.columns))
    end
    records[#records]._has_continuation = false
    self.records = records
end

---@param self Block_grid
local function fill_padding(self)
    apply(self, "fill_padding", self.attr.columns)
end

---@self Block
local function remove_padding(self)
    apply(self, "remove_padding")
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
    log.assert(ncol ~= 0, "column count must be greater than 0")
    apply(self, "apply_column_count", ncol)
end

---@self Block
---@self Block_grid
---@param replace {[string]:string}
local function apply_replacements(self, replace)
    for _, record in ipairs(self.records) do
        log.assert(record.kind == CONST.KIND.GRID, "unexpected record kind")
        for icol, cell in ipairs(record.row) do
            for key, val in pairs(replace) do
                cell = cell:gsub(key, val)
            end
            record.row[icol] = cell
        end
    end
end

---@param self Block_grid
local function set_consistent_ncol(self)
    local ncol = Record.get_consistent_ncol(self.records)
    Attr.set_ncol(self.attr, ncol)
end

---@param self Block_grid
local function set_consistent_width(self)
    local width_min = Attr.get_width_array(Attr.grid.new(self.records[1]).columns)
    local width_max = vim.deepcopy(width_min)
    for irec = 2, #self.records do
        local widths = Attr.get_width_array(Attr.grid.new(self.records[irec]).columns)
        for icol, width in ipairs(widths) do
            width_min[icol] = width_min[icol] or 0
            width_max[icol] = width_max[icol] or math.huge
            width_min[icol] = math.min(width_min[icol], width)
            width_max[icol] = math.max(width_max[icol], width)
        end
    end
    for icol = 1, math.min(#self.attr.columns, #width_max) do
        if width_min[icol] == width_max[icol] then
            self.attr.columns[icol].width = width_max[icol]
        end
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
    log.assert(not self.kind, "Block kind already set")
    initialize(self, kind)
end

---@self Block
---@param record Record
function M:add(record)
    self.records[#self.records + 1] = record
end

---@self Block
---@return Ndjson[]
function M:serialize()
    return serialize_records(self)
end

---@self Block
---@param no_normalize boolean
function M:from_buf(no_normalize)
    remove_padding(self)
    if self.kind == CONST.KIND.GRID and not no_normalize then
        unwrap(self)
    end
end

function M.plain.new()
    local self = M.new()
    M.set_kind(self, CONST.KIND.PLAIN)
    M.add(self, Record.plain.new_from_bufline(""))
    return self
end

---@self Block
function M.plain:to_flat()
    for _, record in ipairs(self.records) do
        for key, val in pairs(get_un_escape_map()) do
            record.line = record.line:gsub(key, val)
        end
    end
end

M.plain.inherit_neighbor_attr = nop

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:from_flat()
    apply_replacements(self, get_escape_map())
end

---@self Block_grid
function M.grid:to_flat()
    apply_replacements(self, get_un_escape_map())
end

--- Normalize all rows in a grid block to have the same number of columns.
---@self Block_grid
function M.grid:to_bufdoc()
    apply_column_count(self, #self.attr.columns)
    wrap(self)
    fill_padding(self)
end

---@self Block_grid
function M.grid:infer_consistent_attr()
    if #self.attr.columns ~= 0 then
        return
    end
    set_consistent_ncol(self)
    set_consistent_width(self)
end

---@param self Block_grid
---@param force boolean|nil
function M.grid:set_max_attr(force)
    Attr.grid.set_max_attr(self.attr, self.records, force)
end

---@param self Block_grid
---@return integer[]
function M.grid:get_max_width()
    return Attr.grid.get_max_width(self.records)
end

---@self Block_grid
---@param attrs Attr[]
function M.grid:apply_attrs_by_range(attrs)
    local attr = Attrs.get_attr(attrs, self.attr.range)
    if not attr or not Attr.is_grid(attr) then
        return
    end
    self.attr.wrap_mode = attr.wrap_mode
    self.attr.fit_span = attr.fit_span
    if #self.attr.columns == 0 then
        self.attr.columns = vim.deepcopy(attr.columns)
    else
        for icol, column in ipairs(self.attr.columns) do
            if column.width <= 0 then
                column.width = attr.columns[icol].width
            end
        end
    end
end

---@param self Block_grid
---@param attrs Attr[]
---@param cur_row integer
function M.grid:inherit_neighbor_attr(attrs, cur_row)
    local attr = Attrs.get(attrs, cur_row)
    if not attr or not Attr.is_grid(attr) then
        return
    end
    if #self.attr.columns == 0 then
        self.attr.columns = vim.deepcopy(attr.columns)
    end
end

---@self Block_plain
---@return boolean
function M.plain:has_width()
    return true
end

---@self Block_grid
---@return boolean
function M.grid:has_width()
    for _, column in ipairs(self.attr.columns) do
        if column.width <= 0 then
            return false
        end
    end
    return true
end

return M
