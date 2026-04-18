local ns = require("tirenvi.ns")
local buffer = require("tirenvi.state.buffer")
local Range = require("tirenvi.util.range")
local config = require("tirenvi.config")

local M = {}

---@class Attr
---@field col_count integer
---@field widths integer[]

---@param bufnr number
---@param range Range
---@param attr Attr
---@return integer id
function M.set(bufnr, range, attr)
    range.last = math.max(range.first, range.last)
    range.last = math.min(range.last, buffer.line_count(bufnr) - 1)
    local opts = {
        end_row = range.last,
        end_col = 0,
        right_gravity = false,
        end_right_gravity = true,
        strict = false,
        invalidate = false,
        user_data = attr,
    }
    if vim.log.levels.DEBUG >= config.log.level then
        --opts.hl_group = "TirenviDebugLine"
        opts.hl_eol = false
        opts.virt_text = { { tostring("ATTR"), "ErrorMsg" } }
        opts.virt_text_pos = "eol_right_align" -- eol
        --opts.sign_text = tostring("AT"):sub(-2)
        opts.sign_hl_group = "ErrorMsg"
    end
    return vim.api.nvim_buf_set_extmark(bufnr, ns.ATTR, range.first, 0, opts)
end

---@param bufnr number
---@return { id: integer, range: Range, attr: Attr }[]
function M.get_all(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(
        bufnr,
        ns.ATTR,
        { 0, 0 },
        { -1, -1 },
        { details = true }
    )
    local results = {}
    for i = 1, #extmarks do
        local id = extmarks[i][1]
        local start_row = extmarks[i][2]
        local details = extmarks[i][4]
        local end_row = details.end_row or start_row
        local attr = details.user_data
        results[#results + 1] = {
            id = id,
            range = Range.new(start_row, end_row),
            attr = attr,
        }
    end
    return results
end

---@param bufnr number
---@param row number
---@return { id: integer, range: Range, attr: Attr }|nil
function M.find(bufnr, row)
    local extmarks = vim.api.nvim_buf_get_extmarks(
        bufnr,
        ns.ATTR,
        { row, 0 },
        { row, -1 },
        { details = true }
    )
    for i = 1, #extmarks do
        local id = extmarks[i][1]
        local start_row = extmarks[i][2]
        local details = extmarks[i][4]
        local end_row = details.end_row or start_row
        if row >= start_row and row <= end_row then
            return {
                id = id,
                range = Range.new(start_row, end_row),
                attr = details.user_data,
            }
        end
    end
    return nil
end

---@param bufnr number
---@param id integer
function M.delete(bufnr, id)
    vim.api.nvim_buf_del_extmark(bufnr, ns.ATTR, id)
end

---@param bufnr number
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns.ATTR, 0, -1)
end

return M
