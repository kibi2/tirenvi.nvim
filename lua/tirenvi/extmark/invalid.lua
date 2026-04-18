local config = require("tirenvi.config")
local ns = require("tirenvi.ns")
local buffer = require("tirenvi.state.buffer")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

---@param bufnr number
---@param range Range
---@param id integer
function M.set_range(bufnr, range, id)
    range.last = math.max(range.first, range.last) -- If a line is deleted, first > last, so we normalize it
    range.last = math.min(range.last, buffer.line_count(bufnr) - 1)
    local line = buffer.get_line(bufnr, range.last)
    local end_col = #line
    local opts = {
        id = id,
        end_row = range.last,
        end_col = end_col,
        right_gravity = false,
        end_right_gravity = true,
        strict = false,
        invalidate = false,
    }
    if vim.log.levels.DEBUG >= config.log.level then
        opts.hl_group = "TirenviDebugLine"
        opts.hl_eol = false
        opts.virt_text = { { tostring(id), "ErrorMsg" } }
        opts.virt_text_pos = "eol_right_align" -- eol
        opts.sign_text = tostring(id):sub(-2)
        opts.sign_hl_group = "ErrorMsg"
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns.INVALID, range.first, 0, opts)
end

---@param bufnr number
---@return Range[]
function M.get_range(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(
        bufnr,
        ns.INVALID,
        { 0, 0 },
        { -1, -1 },
        { details = true }
    )
    local ranges = {}
    for index = 1, #extmarks do
        local start_row = extmarks[index][2]
        local end_row = extmarks[index][4].end_row
        ranges[#ranges + 1] = Range.new(start_row, end_row)
    end
    return ranges
end

---@param bufnr number
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns.INVALID, 0, -1)
end

return M
