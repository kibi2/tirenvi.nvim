local config = require("tirenvi.config")          -- Root

local Bufline = require("tirenvi.parser.bufline") -- Parser
local buf_parser = require("tirenvi.parser.buf_parser")

local Context = require("tirenvi.io.context")     -- IO

local CursorNvim = require("tirenvi.cursor.nvim") -- Cursor

local errors = require("tirenvi.util.errors")     -- Util
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param is_around boolean|nil
local function setup_vl(is_around)
    local ctx = Context.from_buf()
    is_around = is_around or false
    local count = vim.v.count1
    local rect, lines = Bufline.get_block_rect(ctx, count, is_around)
    if not rect then
        return
    end
    if not buf_parser.table_is_aligned(lines) then
        notify.error(errors.ERR.TABLE_IS_NOT_ALIGNED)
        return
    end
    CursorNvim.move_byte(ctx, rect.row.first, rect.col.first)
    vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
    vim.cmd("normal! o")
    CursorNvim.move_byte(ctx, rect.row.last, rect.col.last)
end

local function setup_vil()
    setup_vl()
end

local function setup_val()
    setup_vl(true)
end

--#endregion
-- =============================================================================
-- Public API

function M.setup()
    vim.keymap.set({ "x" }, "i" .. config.textobj.column, setup_vil, {
        desc = "Inner column",
    })
    vim.keymap.set({ "x" }, "a" .. config.textobj.column, setup_val, {
        desc = "Around column",
    })
end

return M
