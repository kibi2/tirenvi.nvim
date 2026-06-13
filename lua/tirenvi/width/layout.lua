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
---@param win_size integer
---@return integer
local function get_size(block, win_size)
    local columns = block.attr.columns
    local ncol = columns and #columns or #block.records
    return win_size - ncol - 1
end

---@param block Block
---@param win_size integer
local function fit_block(block, win_size)
    local total = Attr.get_total_width(block.attr)
    local columns = block.attr.columns
    local size = get_size(block, win_size)
    for _, column in ipairs(columns or {}) do
        column.width = math.max(math.ceil(size * column.width / total), Cell.MIN_WIDTH)
    end
    local indieces = sort_column_indices(columns)
    local over = math.min(Attr.get_total_width(block.attr) - size, #columns)
    for index = 1, over do
        columns[indieces[index]].width = math.max(columns[indieces[index]].width - 1, Cell.MIN_WIDTH)
    end
end

---@param tirdoc Document
---@param width_mode WidthModeState
local function fit(tirdoc, width_mode)
    local pages = width_mode.pages or 1
    local width = width_mode.width or buffer.get_win_width()
    local win_size = pages * width
    Document.set_max_attr(tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            fit_block(block, win_size)
            log.watch("ATTR", Document.debug_attrs(tirdoc, "[88]MODE"))
        end
    end
end

---@param column Attr_column
---@param max Attr_column
---@param win_size integer
local function auto_attr(column, max, win_size)
    if column.width > max.width then
        local delta = column.width - max.width
        local delta = math.min(delta, 6, math.ceil(max.width / 3))
        column.width = max.width + delta
    end
end

---@param block Block
---@param win_size integer
local function auto_block(block, win_size)
    local max_columns = vim.deepcopy(block.attr.columns)
    fit_block(block, win_size)
    log.probe(block.attr.columns)
    log.probe(max_columns)
    for icol = 1, #max_columns do
        auto_attr(block.attr.columns[icol], max_columns[icol], win_size)
    end
end

---@param tirdoc Document
local function auto(tirdoc)
    Document.set_max_attr(tirdoc)
    local win_size = buffer.get_win_width()
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            auto_block(block, win_size)
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
