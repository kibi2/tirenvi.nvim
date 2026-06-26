local Context = require("tirenvi.app.context")
local Bufline = require("tirenvi.core.bufline")
local buf_parser = require("tirenvi.parser.buf_parser")
local config = require("tirenvi.config")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local buffer = require("tirenvi.io.buffer")
local errors = require("tirenvi.util.errors")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

local M = {}

-- private helpers

---@param ctx Context
---@param line_provider LineProvider
---@param is_around boolean|nil
local function setup_vl(ctx, line_provider, is_around)
    is_around = is_around or false
    local count = vim.v.count1
    local rect, lines = Bufline.get_block_rect(ctx, line_provider, count, is_around)
    if not rect then
        return
    end
    if not buf_parser.table_is_aligned(lines) then
        notify.error(errors.ERR.TABLE_IS_NOT_ALIGNED)
        return
    end
    buffer.set_cursor_byte_pos(ctx.winid, rect.row.first, rect.col.first)
    vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
    vim.cmd("normal! o")
    buffer.set_cursor_byte_pos(ctx.winid, rect.row.last, rect.col.last)
end

local function setup_vil()
    local ctx = Context.from_buf()
    local line_provider = LinProvider.new(ctx.bufnr)
    setup_vl(ctx, line_provider)
end

local function setup_val()
    local ctx = Context.from_buf()
    local line_provider = LinProvider.new(ctx.bufnr)
    setup_vl(ctx, line_provider, true)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

function M.setup()
    vim.keymap.set({ "x" }, "i" .. config.textobj.column, setup_vil, {
        desc = "Inner column",
    })
    vim.keymap.set({ "x" }, "a" .. config.textobj.column, setup_val, {
        desc = "Around column",
    })
end

return M
