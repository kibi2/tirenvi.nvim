local Record = require("tirenvi.core.record")
local Cell = require("tirenvi.core.cell")
local WidthModeState = require("tirenvi.width.state")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

M.plain = {}
M.grid = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param cells Cell[]
---@return Attr_column[]
local function get_columns(cells)
    local columns = {}
    local widths = Cell.get_max_widths(cells)
    for _, width in ipairs(widths) do
        width = math.max(width, Cell.MIN_WIDTH)
        columns[#columns + 1] = { width = width }
    end
    return columns
end

---@param records Record_grid[]
---@param icol integer
---@return integer
local function get_max_width(records, icol)
    local max_width = 0
    for _, record in ipairs(records) do
        local width = Cell.get_max_width(record.row[icol])
        max_width = math.max(max_width, width)
    end
    return math.max(max_width, Cell.MIN_WIDTH)
end

---@param columns Attr_column[]|nil
---@return Attr
local function new_from_columns(columns)
    return { columns = columns }
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@return Attr
function M.new()
    return new_from_columns(nil)
end

---@return Attr
function M.plain.new()
    return new_from_columns(nil)
end

---@param record Record_grid|nil
---@return Attr
function M.grid.new(record)
    local self
    if record then
        self = new_from_columns(get_columns(record.row))
    else
        self = new_from_columns({})
    end
    return self
end

---@self Attr
---@param records Record_grid[]
function M.grid:set_max_attr(records)
    local ncol = #self.columns
    if ncol == 0 then
        ncol = Record.get_max_ncol(records)
        M.set_ncol(self, ncol)
    end
    for icol, column in pairs(self.columns) do
        if column.width <= 0 then
            column.width = get_max_width(records, icol)
        end
    end
end

---@param attr Attr
---@return string
function M.get_attr_short(attr)
    local kind = M.is_plain(attr) and "p" or "g"
    local range_str = attr.range and string.format("(%d,%d)", attr.range.first, attr.range.last) or "()"
    return kind .. range_str
end

---@param attr Attr
---@return string
local function get_mode_short(attr)
    if not attr.width_mode then
        return "-"
    elseif attr.width_mode == "wrap" then
        return "w"
    elseif attr.width_mode == "nowrap" then
        return "n"
    else
        log.assert(false, "invalid mode %s", attr.width_mode)
        return "X"
    end
end

---@param attr Attr
---@return string
function M.get_attr_long(attr)
    local widths = M.get_width_array(attr.columns)
    local long   = #widths > 0 and string.format("[%s]", table.concat(widths, ",")) or ""
    return M.get_attr_short(attr) .. get_mode_short(attr) .. long
end

---@param columns Attr_column[]
---@return integer[]
function M.get_width_array(columns)
    if not columns then
        return {}
    end
    local widths = {}
    for _, column in ipairs(columns) do
        widths[#widths + 1] = column.width
    end
    return widths
end

---@param source Attr
---@param target Attr
---@return boolean
function M.is_same_ncol(source, target)
    local columns1 = source.columns or {}
    local columns2 = target.columns or {}
    return #columns1 == #columns2
end

---@param source Attr
---@param target Attr
---@return boolean
function M.is_consistent(source, target)
    if M.is_plain(source) or M.is_plain(target) then
        return true
    end
    return M.is_same_ncol(source, target)
end

---@self Attr|nil
---@return boolean
function M:is_plain()
    if not self then
        return false
    end
    return self.columns == nil
end

---@param self Attr|nil
---@return boolean
function M:is_grid()
    if not self then
        return false
    end
    return not M.is_plain(self)
end

---@param self Attr
---@param ncol integer|nil
function M:set_ncol(ncol)
    if not ncol then
        return
    end
    for icol = 1, ncol do
        self.columns[icol] = { width = 0 }
    end
end

---@param self Attr
---@param last_col integer
---@return integer
function M:get_total_width(last_col)
    if M.is_plain(self) then
        return 0
    end
    last_col = last_col or #self.columns
    last_col = math.min(last_col, #self.columns)
    local total = 0
    for icol = 1, last_col do
        total = total + self.columns[icol].width
    end
    return total
end

---@param self Attr
---@return boolean
function M:is_width_wrap()
    return not self.width_mode or self.width_mode == "wrap"
end

---@param self Attr
---@param cur_col integer
---@return integer
---@return integer
function M:to_cell_col(cur_col)
    if M.is_plain(self) then
        return 0, 0
    end
    local start = 1
    local last
    for icol, column in ipairs(self.columns) do
        last = start + column.width
        if cur_col <= last then
            return icol, cur_col - start - 1
        end
        start = last + 1
    end
    return #self.columns, self.columns[#self.columns].width
end

---@param self Attr
---@param cur_col integer
function M:get(cur_col)
    local icol = M.to_cell_col(self, cur_col)
    return self.columns[icol]
end

---@param self Attr
---@param icol integer
---@return integer
function M:get_start_pos(icol)
    local width = M.get_total_width(self, icol - 1)
    return width + icol + 1
end

return M
