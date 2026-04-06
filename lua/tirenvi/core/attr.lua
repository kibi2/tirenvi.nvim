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
        columns[#columns + 1] = { width = width }
    end
    return columns
end

---@self Attr
---@param source Attr
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
        end
    end
end

---@param columns Attr_column[]
---@return Attr
local function new_from_columns(columns)
    return { columns = columns }
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
        return M.grid.new_from_record(record)
    else
        return new_from_columns({})
    end
end

---@param record Record_grid
---@return Attr
function M.grid.new_from_record(record)
    return new_from_columns(get_columns(record.row))
end

---@param records Record_grid[]
---@return Attr
function M.new_merged_attr(records)
    local attr = M.grid.new()
    for _, record in ipairs(records) do
        merge(attr, M.grid.new_from_record(record))
    end
    return attr
end

return M
