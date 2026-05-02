local Cell = require("tirenvi.core.cell")
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
    local widths = Cell.get_widths(cells)
    for _, width in ipairs(widths) do
        width = math.max(width, 2)
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
        local width = Cell.get_width(record.row[icol])
        max_width = math.max(max_width, width)
    end
    return math.max(max_width, 2)
end

---@param columns Attr_column[]
---@return Attr
local function new_from_columns(columns)
    return { columns = columns, max = false }
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@return Attr
function M.new()
    return new_from_columns({})
end

---@self Attr
---@return boolean
function M:is_plain()
    return #self.columns == 0
end

---@param self Attr|nil
---@param source Attr|nil
---@param allow_plain boolean
---@return boolean
function M:is_conflict(source, allow_plain)
    if not self or not source then
        return false
    end
    if #self.columns == #source.columns then
        return false
    end
    if not allow_plain then
        return true
    end
    if #self.columns == 0 or #source.columns == 0 then
        return false
    end
    return true
end

---@return Attr
function M.plain.new()
    return M.plain.new_from_record()
end

---@return Attr
function M.plain.new_from_record()
    return new_from_columns({})
end

---@param record Record_grid|nil
---@return Attr
function M.grid.new(record)
    if record then
        return M.grid.new_from_record(record.row)
    else
        return new_from_columns({})
    end
end

---@param cells Cell[]
---@return Attr
function M.grid.new_from_record(cells)
    return new_from_columns(get_columns(cells))
end

---@self Attr
---@param ncol integer
---@param records Record_grid[]
function M.grid:new_max_width(ncol, records)
    self.columns = {}
    for icol = 1, ncol do
        local width = get_max_width(records, icol)
        self.columns[icol] = { width = width }
    end
end

---@self Attr
---@param records Record_grid[]
function M.grid:auto_width(records)
    for icol, column in ipairs(self.columns) do
        if column.width == 0 then
            column.width = get_max_width(records, icol)
        end
    end
end

---@self Attr
---@param icol integer
---@param width integer|nil
function M.grid:set_width(icol, width)
    if not width then
        return
    end
    self.columns[icol] = self.columns[icol] or {}
    self.columns[icol].width = width == 0 and 0 or math.max(width, 2)
end

---@self Attr
---@param widths integer[]
function M:set_widths(widths)
    for icol, width in ipairs(widths) do
        M.grid.set_width(self, icol, width)
    end
end

---@param self Attr
---@param cells string[]
function M.grid:merge(cells)
    local attr = M.grid.new_from_record(cells)
    local columns = self.columns
    if #columns ~= #attr.columns then
        self.max = true
    end
    for icol, column in ipairs(attr.columns) do
        columns[icol] = columns[icol] or { width = 0 }
        if columns[icol].width ~= column.width then
            self.max = true
            columns[icol].width = math.max(columns[icol].width, column.width)
        end
    end
end

---@param self Attr
---@param attrs Attr[]
function M.get_attr(self, attrs)
    -- TODO check range
    return nil
end

return M
