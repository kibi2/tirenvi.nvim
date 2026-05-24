local config = require("tirenvi.config")
local namespaces = require("tirenvi.io.namespaces")
local buffer = require("tirenvi.io.buffer")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local M = {}

---@param bufnr number
---@param range Range
---@param id integer
local function show_debug_marks(bufnr, range, id)
    if vim.log.levels.DEBUG < config.log.level then
        return
    end
    local start0, end0 = Range.to_vim(range)
    local opts = {
        id = id,
        end_row = end0 - 1,
        end_col = 1000,
        right_gravity = false,
        end_right_gravity = true,
        strict = false,
        invalidate = false,
        --
        hl_group = "TirenviDebugLine",
        hl_eol = false,
        --virt_text = { { tostring(id), "ErrorMsg" } },
        --virt_text_pos = "eol_right_align", -- eol
        sign_text = tostring(id):sub(-2),
        sign_hl_group = "ErrorMsg",
    }
    vim.api.nvim_buf_set_extmark(bufnr, namespaces.INVALID, start0, 0, opts)
end

---@param bufnr number
---@param ranges Range[]|nil
function M.set_ranges(bufnr, ranges)
    buffer.set(bufnr, buffer.IKEY.DIRTY, ranges)
    if not ranges then
        return
    end
    log.watch("INVD", ranges)
    for irange, range in ipairs(ranges) do
        show_debug_marks(bufnr, range, irange)
    end
end

---@param bufnr number
---@return Range[]
function M.get_ranges(bufnr)
    return buffer.get(bufnr, buffer.IKEY.DIRTY) or {}
end

---@param bufnr number
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, namespaces.INVALID, 0, -1)
    M.set_ranges(bufnr, nil)
end

return M
