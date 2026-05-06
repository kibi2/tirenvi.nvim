local config = require("tirenvi.config")
local namespaces = require("tirenvi.io.namespaces")
local buffer = require("tirenvi.io.buffer")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

---@param bufnr number
---@param ranges Range[]|nil
function M.set_ranges(bufnr, ranges)
    buffer.set(bufnr, buffer.IKEY.INVALID, ranges)
    if not ranges then
        return
    end
    log.watch("INVD", ranges)
    for irange, range in ipairs(ranges) do
        M.set_range(bufnr, range, irange)
    end
end

---@param bufnr number
---@return Range[]
function M.get_ranges(bufnr)
    local ranges = buffer.get(bufnr, buffer.IKEY.INVALID) or {}
    local new_ranges = {}
    for _, range in ipairs(ranges) do
        new_ranges[#new_ranges + 1] = Range.from_lua(range.first, range.last)
    end
    return new_ranges
end

---@param bufnr number
---@param range Range
---@param id integer
function M.set_range(bufnr, range, id)
    local start0, end0 = range:to_vim()
    end0 = math.max(start0, end0) -- If a line is deleted, first > last, so we normalize it
    end0 = math.min(end0, buffer.line_count(bufnr) - 1)
    local line = buffer.get_line(bufnr, end0 + 1)
    local end_col = #line
    local opts = {
        id = id,
        end_row = end0,
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
    vim.api.nvim_buf_set_extmark(bufnr, namespaces.INVALID, start0, 0, opts)
end

---@param bufnr number
---@return Range[]
function M.get_range(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(
        bufnr,
        namespaces.INVALID,
        { 0, 0 },
        { -1, -1 },
        { details = true }
    )
    local ranges = {}
    for index = 1, #extmarks do
        local start0 = extmarks[index][2]
        local end0 = extmarks[index][4].end_row
        ranges[#ranges + 1] = Range.from_vim(start0, end0)
    end
    return ranges
end

---@param bufnr number
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, namespaces.INVALID, 0, -1)
    M.set_ranges(bufnr, nil)
end

return M
