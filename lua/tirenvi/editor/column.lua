local config = require("tirenvi.config")
local buffer = require("tirenvi.state.buffer")
local vim_parser = require("tirenvi.core.vim_parser")
local tir_vim = require("tirenvi.core.tir_vim")
local ui = require("tirenvi.ui")
local Attr = require("tirenvi.core.attr")
local log = require("tirenvi.util.log")

local M = {}

-- private helpers

---@return integer|nil
---@return integer|nil
local function get_current_col()
    local irow, icol0 = unpack(vim.api.nvim_win_get_cursor(0))
    local icol = icol0 + 1
    local cline = vim.api.nvim_get_current_line()
    local cbyte_pos = tir_vim.get_pipe_byte_position(cline)
    if #cbyte_pos == 0 then
        return nil, nil
    end
    return irow, tir_vim.get_current_col_index(cbyte_pos, icol)
end

---@param mode string
local function change_width(mode)
    local bufnr = vim.api.nvim_get_current_buf()
    log.probe("set_width called")
    local width = vim.v.count1
    log.probe(width)
    local irow, icol = get_current_col()
    log.probe(irow)
    log.probe(icol)
    if not irow or not icol then
        return
    end
    local lines = buffer.get_lines(bufnr, 0, -1, false)
    local top = tir_vim.get_block_top_nrow(lines, irow)
    local bottom = tir_vim.get_block_bottom_nrow(lines, irow)
    log.probe(top)
    log.probe(bottom)
    local lines = buffer.get_lines(bufnr, top - 1, bottom, false)
    local blocks = vim_parser.parse(lines)
    local block = blocks[1]
    log.probe(block)
    assert(block.kind == "grid")
    log.probe(block.attr)
    log.probe(block.attr.columns)
    local old_width = block.attr.columns[icol].width
    if mode == "set" then
        block.attr.columns[icol].width = width
    elseif mode == "increase" then
        block.attr.columns[icol].width = old_width + width
    elseif mode == "decrease" then
        block.attr.columns[icol].width = old_width - width
    end
    log.probe(block.attr.columns)
    local vi_lines = vim_parser.unparse(blocks)
    ui.set_lines(bufnr, top - 1, bottom, vi_lines)
end

-- public API

function M.increase_width()
    change_width("increase")
end

function M.decrease_width()
    change_width("decrease")
end

function M.set_width()
    change_width("set")
end

function M.setup()
    vim.keymap.set("n", "=" .. config.textobj.cell, M.set_width, { desc = "set column width" })
    vim.keymap.set("n", ">" .. config.textobj.cell, M.increase_width, { desc = "increase column width" })
    vim.keymap.set("n", "<" .. config.textobj.cell, M.decrease_width, { desc = "decrease column width" })
end

return M
