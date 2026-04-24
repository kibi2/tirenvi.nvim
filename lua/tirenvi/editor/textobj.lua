local Parser = require("tirenvi.core.parser")
local Context = require("tirenvi.core.context")
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
    local context = Context.from_buf()
    local pos = tir_vim.get_block_rect(line_provider, count, is_around, Context.is_allow_plain(context))
    if not pos then
        return
    end
    vim.api.nvim_win_set_cursor(0, { pos.row.first, pos.col.first - 1, })
    vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
    vim.cmd("normal! o")
    vim.api.nvim_win_set_cursor(0, { pos.row.last, pos.col.last - 1, })
end

local function setup_vil()
    local line_provider = LinProvider.new()
    setup_vl(line_provider)
end

local function setup_val()
    local line_provider = LinProvider.new()
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
