local CONST = require("tirenvi.constants")
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
        columns[#columns + 1] = { align = CONST.ALIGN.LEFT, width = width }
    end
    return columns
end

---@self Attr_grid
---@param source Attr_grid
local function merge(self, source)
    ---@type Attr_column[]
    local mcols = self.columns
    ---@type Attr_column[]
    local scols = source.columns
    local count = math.max(#mcols, #scols)
    for index = 1, count do
        local mcol = mcols[index]
        local scol = scols[index]
        if not mcol then
            mcols[index] = scol
        elseif scol then
            mcol.width = math.max(mcol.width, scol.width)
            if mcol.align ~= scol.align then
                mcol.align = CONST.ALIGN.LEFT
            end
        end
    end
end

---@param columns Attr_column[]
---@return Attr_grid
local function new_from_columns(columns)
    return { kind = CONST.KIND.ATTR_GRID, columns = columns }
end

---@param records Record_grid[]
---@return Attr_grid
local function new_merged_attr(records)
    local attr = M.grid.new()
    for _, record in ipairs(records) do
        merge(attr, M.grid.new_from_record(record))
    end
    return attr
end

---@self Attr_grid
---@param source Attr_grid
local function extend(self, source)
    if #self.columns == 0 then
        self.columns = source.columns
    else
        for index, column in ipairs(self.columns) do
            column.align = column.align or source.columns[index].align
            column.width = column.width or source.columns[index].width
        end
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@return Attr_grid
function M.new()
    return {}
end

---@self Attr
---@return boolean
function M:is_empty()
    if self == nil then
        return true
    end
    if not self.kind then
        return true
    end
    if not self.columns or #self.columns == 0 then
        return true
    end
    return false
end

---@self Attr
---@param source Attr
---@return boolean
function M:is_conflict(source)
    if M.is_empty(self) or M.is_empty(source) then
        return false
    end
    if self.kind ~= source.kind then
        return true
    end
    if #self.columns ~= #source.columns then
        return true
    end
    return false
end

---@return Attr_plain
function M.plain.new()
    return M.plain.new_from_record()
end

---@return Attr_plain
function M.plain.new_from_record()
    return { kind = CONST.KIND.ATTR_PLAIN, }
end

---@param record Record_grid | nil
---@return Attr_grid
function M.grid.new(record)
    if record then
        return M.grid.new_from_record(record)
    else
        return new_from_columns({})
    end
end

---@param record Record_grid
---@return Attr_grid
function M.grid.new_from_record(record)
    return new_from_columns(get_columns(record.row))
end

---@self Attr_grid
---@param records Record_grid[]
function M.grid:extend(records)
    extend(self, new_merged_attr(records))
end

---@self Attr_grid
---@return boolean
function M.grid:has_all()
    if not self or self.kind ~= CONST.KIND.ATTR_GRID then
        return false
    end
    local cols = self.columns
    if not cols or #cols == 0 then
        return false
    end
    for index = 1, #cols do
        local col = cols[index]
        if not col or not col.width or not col.align then
            return false
        end
    end
    return true
end

return M
