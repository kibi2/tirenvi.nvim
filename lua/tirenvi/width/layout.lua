local Document    = require("tirenvi.core.document")
local Cell        = require("tirenvi.core.cell")
local Attr        = require("tirenvi.core.attr")
local buffer      = require("tirenvi.io.buffer")
local width_state = require("tirenvi.width.state")
local log         = require("tirenvi.util.log")

local M           = {}

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

---@param tirdoc Document
local function fix(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        for _, column in ipairs(block.attr.columns or {}) do
            column.width = column.fix_width
        end
    end
    Document.set_max_attr(tirdoc)
end

---@param tirdoc Document
local function clear_width(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        for _, column in ipairs(block.attr.columns or {}) do
            column.width = 0
        end
    end
end

---@param tirdoc Document
local function max(tirdoc)
    Document.set_max_attr(tirdoc)
end

---@param block Block
---@param win_width integer
---@return integer
local function get_size(block, win_width)
    local columns = block.attr.columns
    local ncol = columns and #columns or #block.records
    return win_width - ncol - 1
end

---@param block Block
---@param win_width integer
local function fit_auto_block(block, win_width)
    local total = 0
    local logws = {}
    for _, column in ipairs(block.attr.columns) do
        -- local logw = math.log(column.width)
        local logw = column.width
        logws[#logws + 1] = logw
        total = total + logw
    end
    local columns = block.attr.columns
    local size = get_size(block, win_width)
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

---@param block Block
---@param win_width integer
local function fit_block(block, win_width)
    local total = Attr.get_total_width(block.attr)
    local columns = block.attr.columns
    local size = get_size(block, win_width)
    for _, column in ipairs(columns or {}) do
        column.width = math.max(math.ceil(size * column.width / total), Cell.MIN_WIDTH)
    end
    shrink_to_fit(block.attr, size)
end

---@param tirdoc Document
---@param width_mode WidthModeState
local function fit(tirdoc, width_mode)
    local pages = width_mode.number[1] or 1
    local width = width_mode.number[2] or buffer.get_win_width()
    local win_width = pages * width
    Document.set_max_attr(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            fit_block(block, win_width)
            log.watch("ATTR", Document.debug_attrs(tirdoc, "[88]MODE"))
        end
    end
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
---@param win_width integer
local function auto_expand(column, max, win_width)
    local width = math.ceil(math.sqrt(max.width * 3 / 2))
    if width <= column.width then
        return
    end
    column.width = math.min(width, math.floor(win_width / 4))
end

---@param column Attr_column
---@param max Attr_column
---@param win_width integer
---@return boolean
local function auto_attr(column, max, win_width)
    if max.width < column.width then
        auto_shrink(column, max)
        return false
    else
        auto_expand(column, max, win_width)
        return true
    end
end

---@param block Block
---@param win_width integer
local function auto_block(block, win_width)
    local max_columns = vim.deepcopy(block.attr.columns)
    fit_auto_block(block, win_width)
    local is_wrap = false
    for icol = 1, #max_columns do
        is_wrap = is_wrap or auto_attr(block.attr.columns[icol], max_columns[icol], win_width)
    end
end

---@param tirdoc Document
local function auto(tirdoc)
    Document.set_max_attr(tirdoc)
    local win_width = buffer.get_win_width()
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            auto_block(block, win_width)
        end
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param width_mode  WidthModeState
---@param tirdoc Document
function M.compute(width_mode, tirdoc)
    if width_mode.mode == "fix" then
        fix(tirdoc)
    else
        clear_width(tirdoc)
        if width_mode.mode == "max" then
            max(tirdoc)
        elseif width_mode.mode == "fit" then
            fit(tirdoc, width_mode)
        elseif width_mode.mode == "auto" then
            auto(tirdoc)
        end
    end
end

return M
