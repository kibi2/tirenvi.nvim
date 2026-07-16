local config = require("tirenvi.config")
local Record = require("tirenvi.core.record")
local Cell = require("tirenvi.core.cell")
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
    local max_width = Cell.MIN_WIDTH
    for _, record in ipairs(records) do
        local width = Cell.get_max_width(record.row[icol])
        max_width = math.max(max_width, width)
    end
    return max_width
end

---@param columns Attr_column[]|nil
---@return Attr
local function new_from_columns(columns)
    local self = {}
    self.columns = columns
    self.fit_span = 0
    return self
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
---@param force boolean|nil
function M.grid:set_max_attr(records, force)
    force = force or false
    local ncol = #self.columns
    if ncol == 0 then
        ncol = Record.get_max_ncol(records)
        M.set_ncol(self, ncol)
    end
    for icol, column in pairs(self.columns) do
        if force or column.width <= 0 then
            column.width = get_max_width(records, icol)
        end
    end
end

---@param records Record_grid[]
---@return integer[]
function M.grid.get_max_width(records)
    local widths = {}
    local ncol = Record.get_max_ncol(records)
    for icol = 1, ncol do
        widths[#widths + 1] = get_max_width(records, icol)
    end
    return widths
end

---@param self Attr
---@return string
function M.get_attr_short(self)
    local kind = M.is_plain(self) and "p" or "g"
    local range_str = self.range and string.format("(%d,%d)", self.range.first, self.range.last) or "()"
    local prefix = vim.trim(self.prefix or "")
    return kind .. prefix .. range_str
end

local short_map = { plain = "", nowrap = "n", wrap_auto = "a", wrap_fit = "f", wrap_width = "w" }
---@param self Attr
---@return string
local function get_mode_short(self)
    local wrap_mode = M.get_wrap_mode(self)
    return short_map[wrap_mode]
end

---@param attr Attr
---@param ccol integer|nil
---@return string
function M.get_attr_long(attr, ccol)
    local widths = M.get_width_array(attr.columns)
    ---@cast widths string[]
    local long = ""
    if ccol and M.is_plain(attr) then
        long = "*"
    else
        if ccol then
            widths[ccol] = widths[ccol] .. "*"
        end
        long = #widths > 0 and string.format("[%s]", table.concat(widths, ",")) or ""
    end
    local fit_span = attr.fit_span == 0 and "" or tostring(attr.fit_span)
    return M.get_attr_short(attr) .. get_mode_short(attr) .. fit_span .. long
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
    return self and self.columns == nil
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
    for icol = 1, ncol or 0 do
        self.columns[icol] = { width = 0 }
    end
end

---@param self Attr
---@param last_col integer|nil
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
---@return  WrapMode
function M:get_wrap_mode()
    if M.is_plain(self) then
        return "plain"
    end
    if not self.wrap_mode then
        if config.table.wrap_mode == "nowrap" then
            self.wrap_mode = "nowrap"
        else
            self.wrap_mode = "wrap_auto"
        end
    end
    if self.wrap_mode == "wrap_fit" then
        if self.fit_span == 0 then
            self.wrap_mode = "wrap_auto"
        end
    end
    return self.wrap_mode
end

---@param self Attr
---@return "wrap"|"nowrap"|"auto"
function M:get_wrap_kind()
    log.assert(not M.is_plain(self), "is not plain attr: %s", vim.inspect(self))
    local mode = M.get_wrap_mode(self)
    if mode == "nowrap" then
        return "nowrap"
    elseif mode == "wrap_auto" then
        return "auto"
    else
        return "wrap"
    end
end

---@param self Attr
---@param col_disp integer
---@return integer
---@return integer
function M:to_cell_col(col_disp)
    if M.is_plain(self) then
        return 0, 0
    end
    local start = 1
    local last
    for icol, column in ipairs(self.columns) do
        last = start + column.width
        if col_disp <= last then
            return icol, col_disp - start
        end
        start = last + 1
    end
    return #self.columns, self.columns[#self.columns].width
end

---@param self Attr
---@param col_byte integer
function M:get(col_byte)
    local icol = M.to_cell_col(self, col_byte)
    return self.columns[icol]
end

---@param self Attr
---@param icol integer
---@return integer
function M:get_start_pos(icol)
    if M.is_plain(self) then
        return 1
    end
    local width = M.get_total_width(self, icol - 1)
    return width + icol + 1
end

---@param self Attr
function M:toggle_wrap_mode()
    if not self or M.is_plain(self) then
        return
    end
    if M.get_wrap_mode(self) == "nowrap" then
        if self.fit_span == 0 then
            self.wrap_mode = "wrap_auto"
        else
            self.wrap_mode = "wrap_fit"
        end
    else
        -- self.fit_span = M.get_fit_span(self)
        self.wrap_mode = "nowrap"
    end
end

---@param self Attr
---@return integer
function M.get_fit_span(self)
    return M.get_total_width(self) + #self.columns + 1
end

return M
