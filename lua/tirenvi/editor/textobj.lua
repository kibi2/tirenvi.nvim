local tir_vim = require("tirenvi.core.tir_vim")
local buffer = require("tirenvi.state.buffer")
local log = require("tirenvi.util.log")

local function setup_which_key()
    local ok, wk = pcall(require, "which-key")
    if ok then
        wk.add({
            { "al", desc = "Around column", mode = { "o", "x" } },
            { "il", desc = "Inner column",  mode = { "o", "x" } },
        })
    end
end

local M = {}

---@param is_around boolean|nil
local function setup_vl(is_around)
    is_around = is_around or false
    local count = vim.v.count1
    local lines = buffer.get_lines(0, 0, -1, false)
    local pos = tir_vim.get_select(lines, count, is_around)
    if not pos then
        return
    end
    vim.api.nvim_win_set_cursor(0, { pos.start_row, pos.start_col - 1, })
    vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
    vim.cmd("normal! o")
    vim.api.nvim_win_set_cursor(0, { pos.end_row, pos.end_col - 1, })
end

function M.setup_vil()
    setup_vl()
end

function M.setup_val()
    setup_vl(true)
end

-- setup
function M.setup(opts)
    setup_which_key()
    vim.keymap.set("x", "il", M.setup_vil)
    vim.keymap.set("x", "al", M.setup_val)
end

return M
