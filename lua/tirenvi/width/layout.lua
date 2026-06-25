local Document   = require("tirenvi.core.document")
local Block      = require("tirenvi.core.block")
local Cell       = require("tirenvi.core.cell")
local Attr       = require("tirenvi.core.attr")
local buffer     = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local util       = require("tirenvi.util.util")
local log        = require("tirenvi.util.log")

local M          = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param columns { width: integer }[]
---@return integer[]
local function sort_column_indices2(columns)
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

---@param widths integer[]
---@return integer[]
local function sort_column_indices(widths)
    local indices = {}
    for index = 1, #widths do
        indices[index] = index
    end
    table.sort(indices, function(index1, index2)
        local width1 = widths[index1]
        local width2 = widths[index2]
        if width1 ~= width2 then
            return width1 > width2
        end
        return index1 > index2
    end)
    return indices
end

---@param block Block_grid
local function fix(block)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
local function clear_width(block)
    for _, column in ipairs(block.attr.columns or {}) do
        column.width = 0
    end
end

---@param block Block_grid
local function max(block)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
---@param grid_span integer
---@return integer
local function get_width(block, grid_span)
    local columns = block.attr.columns
    local ncol = columns and #columns or #block.records
    return grid_span - ncol - 1
end

---@param ncol integer
---@param grid_span integer
---@return integer
local function get_fit_width(ncol, grid_span)
    return grid_span - ncol - 1
end

---@param block Block_grid
---@param max_span integer
local function fit_auto_block2(block, max_span)
    Block.grid.set_max_attr(block, true)
    local total = 0
    local logws = {}
    for _, column in ipairs(block.attr.columns) do
        local logw = math.log(column.width)
        --local logw = column.width
        logws[#logws + 1] = logw
        total = total + logw
    end
    local columns = block.attr.columns
    local width = get_width(block, max_span)
    for icol = 1, #columns do
        columns[icol].width = math.max(math.ceil(width * logws[icol] / total), Cell.MIN_WIDTH)
    end
    local indieces = sort_column_indices2(columns)
    local over = math.min(Attr.get_total_width(block.attr) - width, #columns)
    for index = 1, over do
        columns[indieces[index]].width = math.max(columns[indieces[index]].width - 1, Cell.MIN_WIDTH)
    end
end

---@param widths integer[]
---@return number[]
local function get_weight(widths)
    local total = 0
    local logws = {}
    for _, width in ipairs(widths) do
        local logw = math.log(width)
        logws[#logws + 1] = logw
        total = total + logw
    end
    local weight = {}
    for icol = 1, #widths do
        weight[icol] = logws[icol] / total
    end
    return weight
end

---@param fit_width integer
---@return integer[]
local function get_fit_widths(org_widths, fit_width)
    local weight = get_weight(org_widths)
    local fit_widths = {}
    for icol = 1, #org_widths do
        fit_widths[icol] = math.max(math.ceil(fit_width * weight[icol]), Cell.MIN_WIDTH)
    end
    local indieces = sort_column_indices(fit_widths)
    local over = math.min(util.sum(fit_widths) - fit_width, #fit_widths)
    for index = 1, over do
        local icol = indieces[index]
        fit_widths[icol] = math.max(fit_widths[icol] - 1, Cell.MIN_WIDTH)
    end
    return fit_widths
end

---@param attr Attr
---@param width integer
local function shrink_to_fit(attr, width)
    local columns = attr.columns
    local indieces = sort_column_indices2(columns)
    local over = math.min(Attr.get_total_width(attr) - width, #columns)
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
---@param grid_span integer
local function fit_block2(block, grid_span)
    local columns = block.attr.columns or {}
    local width = get_width(block, grid_span)
    local extra_space = width - #columns * Cell.MIN_WIDTH
    if extra_space <= 0 then
        set_mini_width(columns)
    else
        distribute_log_width(columns, extra_space)
        shrink_to_fit(block.attr, width)
    end
end

---@return integer|nil
local function get_width_from_attrs(attrs)
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
local function get_width_pre()
    return get_width_from_attrs(attr_store.read())
end

---@return integer
local function get_auto_span()
    return buffer.get_win_span()
end

---@param block Block_grid
---@param fit_span integer
---@return integer
local function get_grid_span(block, fit_span)
    return fit_span or get_auto_span()
end

---@param block Block_grid
local function fit(block)
    local grid_span = get_grid_span(block, block.attr.fit_span)
    Block.grid.set_max_attr(block)
    fit_block2(block, grid_span)
    log.watch("ATTR", block.attr)
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
---@param max_span integer
local function auto_expand(column, max, max_span)
    local width = math.ceil(math.sqrt(max.width * 3 / 2))
    if width <= column.width then
        return
    end
    column.width = math.min(width, math.floor(max_span / 4))
end

---@param column Attr_column
---@param max Attr_column
---@param max_span integer
---@return boolean
local function auto_attr(column, max, max_span)
    if max.width < column.width then
        auto_shrink(column, max)
        return false
    else
        auto_expand(column, max, max_span)
        return true
    end
end

---@param block Block_grid
---@param win_width integer
local function auto_block2(block, win_width)
    local max_columns = vim.deepcopy(block.attr.columns)
    fit_block2(block, win_width)
    local is_wrap = false
    for icol = 1, #max_columns do
        is_wrap = is_wrap or auto_attr(block.attr.columns[icol], max_columns[icol], win_width)
    end
end

---@param block Block_grid
local function auto(block)
    Block.grid.set_max_attr(block)
    local win_width = buffer.get_win_span()
    auto_block2(block, win_width)
end

---@param current_width integer[]
---@param extra_width integer
local function expand2(current_width, extra_width)
    local total = 0
    local logws = {}
    for _, width in ipairs(current_width) do
        local logw = math.log(width)
        logws[#logws + 1] = logw
        total = total + logw
    end
    local widths = {}
    for icol = 1, #current_width do
        local extra = math.ceil(extra_width * logws[icol] / total)
        extra = math.min(extra, math.ceil(current_width[icol] * 0.3), 6)
        widths[icol] = extra
    end
    return widths
end

---@param current_width integer[]
---@param extra_width integer
local function expand2(current_width, extra_width)
    local total = 0
    local logws = {}
    for _, width in ipairs(current_width) do
        local logw = math.log(width)
        logws[#logws + 1] = logw
        total = total + logw
    end
    local widths = {}
    for icol = 1, #current_width do
        local extra = math.ceil(extra_width * logws[icol] / total)
        extra = math.min(extra, math.ceil(current_width[icol] * 0.3), 6)
        widths[icol] = extra
    end
    return widths
end

---@param block Block_grid
---@param extra_width integer
---@return integer[]
local function deliver(block, extra_width)
    local current_width = Attr.get_width_array(block.attr.columns)
    return expand2(current_width, extra_width)
end

---@param block Block_grid
local function nowrap(block)
    Block.grid.set_max_attr(block, true)
end

---@param block Block_grid
local function wrap_auto2(block)
    Block.grid.set_max_attr(block, true)
    local win_width = buffer.get_win_span()
    local total_width = Attr.get_total_width(block.attr)
    local fit_width = total_width + #block.attr + 1
    local widths = {}
    if fit_width < win_width then
        widths = deliver(block, win_width - fit_width)
    end
    for icol = 1, #widths do
        block.attr.columns[icol].width = block.attr.columns[icol].width + widths[icol]
    end
end

local PADDING_RATE = 1 / 3
local PADDING_MAX = 6
---@param max_widths integer[]
---@param fit_width integer
---@return integer[]
local function shrink(max_widths, fit_width)
    local fit_widths = get_fit_widths(max_widths, fit_width)
    for icol = 1, #fit_widths do
        local plus = fit_widths[icol] - max_widths[icol]
        plus = math.min(plus, math.ceil(max_widths[icol] * PADDING_RATE), PADDING_MAX)
        fit_widths[icol] = max_widths[icol] + plus
    end
    return fit_widths
end

local WIDTH_MIN = 6
---@param max_widths integer[]
---@param fit_widths integer[]
---@return number
local function get_expand_ratio(max_widths, fit_widths)
    local ratio = 1
    for icol = 1, #fit_widths do
        if fit_widths[icol] < max_widths[icol] then
            ratio = math.max(ratio, WIDTH_MIN / fit_widths[icol])
        end
    end
    return ratio
end

local function expand(max_widths, fit_width)
    local fit_widths = get_fit_widths(max_widths, fit_width)
    local ratio = get_expand_ratio(max_widths, fit_widths)
    if ratio == 1 then
        return fit_widths
    end
    return get_fit_widths(max_widths, math.ceil(fit_width * ratio))
end

---@param block Block_grid
local function wrap_auto(block)
    local max_widths = Block.grid.get_max_width(block)
    local max_width = util.sum(max_widths)
    local fit_span = buffer.get_win_span()
    local fit_width = get_fit_width(#max_widths, fit_span)
    local fit_widths
    if max_width < fit_width then
        fit_widths = shrink(max_widths, fit_width)
    else
        fit_widths = expand(max_widths, fit_width)
    end
    for icol = 1, #fit_widths do
        block.attr.columns[icol] = block.attr.columns[icol] or {}
        block.attr.columns[icol].width = fit_widths[icol]
    end
end

---@param block Block_grid
local function wrap_fit(block)
    local fit_span = block.attr.fit_span or buffer.get_win_span()
    local max_widths = Block.grid.get_max_width(block)
    local fit_width = get_fit_width(#max_widths, fit_span)
    local fit_widths = get_fit_widths(max_widths, fit_width)
    for icol = 1, #fit_widths do
        block.attr.columns[icol].width = fit_widths[icol]
    end
end

---@param block Block_grid
local function wrap_width(block)
    Block.grid.set_max_attr(block)
end

---@param block Block_grid
---@param wrap_mode WrapMode
local function wrap(block, wrap_mode)
    if wrap_mode == "wrap_auto" then
        wrap_auto(block)
    elseif wrap_mode == "wrap_fit" then
        wrap_fit(block)
    elseif wrap_mode == "wrap_width" then
        wrap_width(block)
    else
        log.assert(false, "invalid mode %s", wrap_mode)
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param tirdoc Document
function M.compute(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            local wrap_mode = Attr.get_wrap_mode(block.attr)
            if wrap_mode == "nowrap" then
                nowrap(block)
            elseif wrap_mode then
                wrap(block, wrap_mode)
            end
        end
    end
end

return M
