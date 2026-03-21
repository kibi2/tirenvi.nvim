local config = require("tirenvi.config")
local ns = require("tirenvi.ns")

local M = {}

---@param bufnr number
---@param first integer
---@param last integer
---@param id integer
function M.set_range(bufnr, first, last, id)
    local line = vim.api.nvim_buf_get_lines(bufnr, last, last + 1, false)[1]
    local end_col = #line
    local opts = {
        id = id,
        strict = false,
        right_gravity = false,
        end_right_gravity = true,
        end_row = last,
        end_col = end_col,
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
    vim.api.nvim_buf_set_extmark(bufnr, ns.INVALID, first, 0, opts)
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
        ranges[#ranges + 1] = { first = start_row, last = end_row }
    end
    return ranges
end

---@param bufnr number
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns.INVALID, 0, -1)
end

---@param bufnr number
---@param lnum integer
---@param line string
function M.highlight_header_line(bufnr, lnum, line)
    local npipe = #config.marks.pipe
    vim.api.nvim_buf_set_extmark(bufnr, ns.HIGHLIGHT, lnum, npipe, {
        strict = true,
        end_row = lnum,
        end_col = #line - npipe,
        hl_group = "TirenviHeader",
        priority = 100,
    })
end

return M
