local tir_vim = require("tirenvi.core.tir_vim")
local buffer = require("tirenvi.state.buffer")
local config = require("tirenvi.config")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}

-- private helpers

---@param is_around boolean|nil
local function setup_vl(is_around)
    is_around = is_around or false
    local count = vim.v.count1
    local lines = buffer.get_lines(0, 0, -1)
    local parser = util.get_parser()
    local pos = tir_vim.get_block_rect(lines, count, is_around, parser.allow_plain)
    if not pos then
        return
    end
    vim.api.nvim_win_set_cursor(0, { pos.start_row, pos.start_col - 1, })
    vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
    vim.cmd("normal! o")
    vim.api.nvim_win_set_cursor(0, { pos.end_row, pos.end_col - 1, })
end

-- public API

function M.setup_vil()
    setup_vl()
end

function M.setup_val()
    setup_vl(true)
end

function M.setup()
    vim.keymap.set({ "x" }, "i" .. config.textobj.column, M.setup_vil, {
        desc = "Inner column",
    })

    vim.keymap.set({ "x" }, "a" .. config.textobj.column, M.setup_val, {
        desc = "Around column",
    })
end

return M
