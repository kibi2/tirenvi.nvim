local Document   = require("tirenvi.core.document")
local Block      = require("tirenvi.core.block")
local Cell       = require("tirenvi.core.cell")
local Attr       = require("tirenvi.core.attr")
local buffer     = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local log        = require("tirenvi.util.log")

local M          = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param columns { width: integer }[]
---@return integer[]
local function sort_column_indices(columns)
    local indices = {}
    for index = 1, #columns do
        indices[index] = index
    end
    table.sort(indices, function(index1, index2)
        local width1 = columns[index1].width
        local width2 = columns[index2].width
        if width1 ~= width2 then
            return width1 > width2
        end
        return index1 > index2
    end)
    return indices
end

---@param block Block_grid
local function wrap(block)
    log.probe(block.attr.columns)
    log.probe(block.attr.columns)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
local function fix(block)
    log.probe(block.attr.columns)
    log.probe(block.attr.columns)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
local function clear_width(block)
    for _, column in ipairs(block.attr.columns or {}) do
        column.width = 0
    end
end

---@param block Block_grid
local function nowrap(block)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
local function max(block)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
---@param grid_size integer
---@return integer
local function get_size(block, grid_size)
    local columns = block.attr.columns
    local ncol = columns and #columns or #block.records
    return grid_size - ncol - 1
end

---@param block Block_grid
---@param max_size integer
local function fit_auto_block(block, max_size)
    local total = 0
    local logws = {}
    for _, column in ipairs(block.attr.columns) do
        -- local logw = math.log(column.width)
        local logw = column.width
        logws[#logws + 1] = logw
        total = total + logw
    end
    local columns = block.attr.columns
    local size = get_size(block, max_size)
    for icol = 1, #columns do
        columns[icol].width = math.max(math.ceil(size * logws[icol] / total), Cell.MIN_WIDTH)
    end
    local indieces = sort_column_indices(columns)
    local over = math.min(Attr.get_total_width(block.attr) - size, #columns)
    for index = 1, over do
        columns[indieces[index]].width = math.max(columns[indieces[index]].width - 1, Cell.MIN_WIDTH)
    end
end

---@param attr Attr
---@param size integer
local function shrink_to_fit(attr, size)
    local columns = attr.columns
    local indieces = sort_column_indices(columns)
    local over = math.min(Attr.get_total_width(attr) - size, #columns)
    for index = 1, over do
        columns[indieces[index]].width = math.max(columns[indieces[index]].width - 1, Cell.MIN_WIDTH)
    end
end

---@param columns Attr_column[]
local function set_mini_width(columns)
    for _, column in ipairs(columns) do
        column.width = Cell.MIN_WIDTH
    end
end

---@param columns Attr_column[]
---@param extra_space integer
local function distribute_log_width(columns, extra_space)
    local total = 0
    local logws = {}
    for _, column in ipairs(columns) do
        local logw = math.log(column.width)
        logws[#logws + 1] = logw
        total = total + logw
    end
    for icol = 1, #columns do
        columns[icol].width = Cell.MIN_WIDTH + math.ceil(extra_space * logws[icol] / total)
    end
end

---@param block Block_grid
---@param grid_size integer
local function fit_block(block, grid_size)
    local columns = block.attr.columns or {}
    local size = get_size(block, grid_size)
    local extra_space = size - #columns * Cell.MIN_WIDTH
    if extra_space <= 0 then
        set_mini_width(columns)
    else
        distribute_log_width(columns, extra_space)
        shrink_to_fit(block.attr, size)
    end
end

---@return integer|nil
local function get_size_from_attrs(attrs)
    for _, attr in ipairs(attrs) do
        if Attr.is_grid(attr) then
            local total = #attr.columns + 1
            for _, column in ipairs(attr.columns) do
                total = total + column.width
            end
            return total
        end
    end
    return nil
end

---@return integer|nil
local function get_size_pre()
    return get_size_from_attrs(attr_store.read())
end

---@return integer
local function get_auto_size()
    return buffer.get_win_width()
end

---@param block Block_grid
---@param fit_width integer
---@return integer
local function get_grid_size(block, fit_width)
    return fit_width or get_auto_size()
end

---@param block Block_grid
local function fit(block)
    log.probe(block.attr.columns)
    local grid_size = get_grid_size(block, block.attr.fit_width)
    Block.grid.set_max_attr(block)
    fit_block(block, grid_size)
    log.watch("ATTR", block.attr)
    log.probe(block.attr.columns)
end

---@param column Attr_column
---@param max Attr_column
local function auto_shrink(column, max)
    local delta = column.width - max.width
    local delta = math.min(delta, 6, math.ceil(max.width / 3))
    column.width = max.width + delta
end

---@param column Attr_column
---@param max Attr_column
---@param max_size integer
local function auto_expand(column, max, max_size)
    local width = math.ceil(math.sqrt(max.width * 3 / 2))
    if width <= column.width then
        return
    end
    column.width = math.min(width, math.floor(max_size / 4))
end

---@param column Attr_column
---@param max Attr_column
---@param max_size integer
---@return boolean
local function auto_attr(column, max, max_size)
    if max.width < column.width then
        auto_shrink(column, max)
        return false
    else
        auto_expand(column, max, max_size)
        return true
    end
end

---@param block Block_grid
---@param win_width integer
local function auto_block(block, win_width)
    local max_columns = vim.deepcopy(block.attr.columns)
    fit_auto_block(block, win_width)
    local is_wrap = false
    for icol = 1, #max_columns do
        is_wrap = is_wrap or auto_attr(block.attr.columns[icol], max_columns[icol], win_width)
    end
end

---@param block Block_grid
local function auto(block)
    Block.grid.set_max_attr(block)
    local win_width = buffer.get_win_width()
    auto_block(block, win_width)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param tirdoc Document
function M.compute(tirdoc)
    log.probe(Document.debug_attrs(tirdoc, "[88]MODE:"))
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            if Attr.is_width_wrap(block.attr) then
                wrap(block)
            else
                nowrap(block)
            end
        end
    end
end

return M
