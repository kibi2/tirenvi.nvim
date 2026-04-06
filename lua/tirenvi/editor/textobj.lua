local tir_vim = require("tirenvi.core.tir_vim")
local config = require("tirenvi.config")
local util = require("tirenvi.util.util")
local LinProvider = require("tirenvi.state.buffer_line_provider")
local log = require("tirenvi.util.log")

local M = {}

-- private helpers

---@param line_provider LineProvider
---@param is_around boolean|nil
local function setup_vl(line_provider, is_around)
    is_around = is_around or false
    local count = vim.v.count1
    local parser = util.get_parser()
    local pos = tir_vim.get_block_rect(line_provider, count, is_around, parser.allow_plain)
    if not pos then
        return
    end
    vim.api.nvim_win_set_cursor(0, { pos.start_row, pos.start_col - 1, })
    vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
    vim.cmd("normal! o")
    vim.api.nvim_win_set_cursor(0, { pos.end_row, pos.end_col - 1, })
end

local function setup_vil()
    local line_provider = LinProvider.new(0)
    setup_vl(line_provider)
end

local function setup_val()
    local line_provider = LinProvider.new(0)
    setup_vl(line_provider, true)
end

-- public API

function M.setup()
    vim.keymap.set({ "x" }, "i" .. config.textobj.column, setup_vil, {
        desc = "Inner column",
    })
    vim.keymap.set({ "x" }, "a" .. config.textobj.column, setup_val, {
        desc = "Around column",
    })
end

return M
