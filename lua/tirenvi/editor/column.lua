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
local function change_width(mode, count)
    local bufnr = vim.api.nvim_get_current_buf()
    local irow, icol = get_current_col()
    if not irow or not icol then
        return
    end
    local lines = buffer.get_lines(bufnr, 0, -1, false)
    local top = tir_vim.get_block_top_nrow(lines, irow)
    local bottom = tir_vim.get_block_bottom_nrow(lines, irow)
    local lines = buffer.get_lines(bufnr, top - 1, bottom, false)
    local blocks = vim_parser.parse(lines)
    local block = blocks[1]
    assert(block.kind == "grid")
    local old_width = block.attr.columns[icol].width
    if mode == "set" then
        block.attr.columns[icol].width = count
    elseif mode == "increase" then
        block.attr.columns[icol].width = old_width + count
    elseif mode == "decrease" then
        block.attr.columns[icol].width = old_width - count
    end
    local vi_lines = vim_parser.unparse(blocks)
    ui.set_lines(bufnr, top - 1, bottom, vi_lines)
end

local function set_repeat(cmd)
    pcall(vim.fn["repeat#set"], cmd)
end

-- public API

function M.set_width(count)
    change_width("set", count)
    set_repeat(":" .. count .. "TirSetWidth\n")
end

function M.increase_width(count)
    change_width("increase", count)
    set_repeat(":" .. count .. "TirIncreaseWidth\n")
end

function M.decrease_width(count)
    change_width("decrease", count)
    set_repeat(":" .. count .. "TirDecreaseWidth\n")
end

function M.setup()
    vim.api.nvim_create_user_command("TirSetWidth", function(opts)
        require("tirenvi.editor.column").set_width(opts.count)
    end, { count = true })
    vim.api.nvim_create_user_command("TirIncreaseWidth", function(opts)
        require("tirenvi.editor.column").increase_width(opts.count)
    end, { count = true })
    vim.api.nvim_create_user_command("TirDecreaseWidth", function(opts)
        require("tirenvi.editor.column").decrease_width(opts.count)
    end, { count = true })
    vim.keymap.set("n", "=c", function() vim.cmd(vim.v.count1 .. "TirSetWidth ") end,
        { desc = "set column width" })
    vim.keymap.set("n", ">c", function() vim.cmd(vim.v.count1 .. "TirIncreaseWidth ") end,
        { desc = "increase column width" })
    vim.keymap.set("n", "<c", function() vim.cmd(vim.v.count1 .. "TirDecreaseWidth ") end,
        { desc = "decrease column width" })
end

return M
