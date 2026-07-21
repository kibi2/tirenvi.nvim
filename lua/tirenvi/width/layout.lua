local buf_lines = require("tirenvi.io.buf_lines") -- IO
local buf_state = require("tirenvi.io.buf_state")

local Block     = require("tirenvi.core.block") -- Core
local Cell      = require("tirenvi.core.cell")
local Attr      = require("tirenvi.core.attr")

local util      = require("tirenvi.util.util") -- Util
local log       = require("tirenvi.util.log")

-- =============================================================================
local M         = {}

-- =============================================================================
--#region Private

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

---@param ncol integer
---@param grid_span integer
---@return integer
local function get_fit_width(ncol, grid_span)
    return grid_span - ncol - 1
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

---@param block Block_grid
local function nowrap(block)
    Block.grid.set_max_attr(block, true)
end

local PADDING_RATE = 1 / 3
local PADDING_MAX = 6
---@param max_widths integer[]
---@param max_width integer
---@param fit_width integer
---@return integer[]
local function shrink(max_widths, max_width, fit_width)
    local plus_widths = get_fit_widths(max_widths, fit_width - max_width)
    for icol = 1, #plus_widths do
        local plus = math.min(plus_widths[icol],
            math.ceil(max_widths[icol] * PADDING_RATE),
            PADDING_MAX)
        plus_widths[icol] = max_widths[icol] + plus
    end
    return plus_widths
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

---@param winid number
---@param block Block_grid
local function wrap_auto(winid, block)
    local max_widths = Block.grid.get_max_width(block)
    local max_width = util.sum(max_widths)
    local fit_span = buf_state.get_win_span(winid)
    local fit_width = get_fit_width(#max_widths, fit_span)
    local fit_widths
    if max_width < fit_width then
        fit_widths = shrink(max_widths, max_width, fit_width)
    else
        fit_widths = expand(max_widths, fit_width)
    end
    for icol = 1, #fit_widths do
        block.attr.columns[icol] = block.attr.columns[icol] or {}
        block.attr.columns[icol].width = fit_widths[icol]
    end
end

---@param winid number
---@param block Block_grid
local function wrap_fit(winid, block)
    local fit_span = block.attr.fit_span or buf_state.get_win_span(winid)
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

---@param winid number
---@param block Block_grid
---@param wrap_mode WrapMode
local function wrap(winid, block, wrap_mode)
    if wrap_mode == "wrap_auto" then
        wrap_auto(winid, block)
    elseif wrap_mode == "wrap_fit" then
        wrap_fit(winid, block)
    elseif wrap_mode == "wrap_width" then
        wrap_width(block)
    else
        log.assert(false, "invalid mode %s", wrap_mode)
    end
end

--#endregion
-- =============================================================================
-- Public API

---@param winid number
---@param tirdoc Document
function M.compute(winid, tirdoc)
    for _, block in ipairs(tirdoc.blocks) do
        if block.kind == "grid" then
            local wrap_mode = Attr.get_wrap_mode(block.attr)
            if wrap_mode == "nowrap" then
                nowrap(block)
            elseif wrap_mode then
                wrap(winid, block, wrap_mode)
            end
        end
    end
end

return M
