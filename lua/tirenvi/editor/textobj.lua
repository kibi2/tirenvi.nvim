local tir_vim = require("tirenvi.core.tir_vim")
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

function M.setup_vl(opts)
    vim.keymap.set("x", "il", function()
        log.probe("xil")
        local count = vim.v.count1
        local pos = tir_vim.get_select(count)
        if not pos then
            return
        end
        vim.api.nvim_win_set_cursor(0, { pos.start_row, pos.start_col - 1, })
        vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
        vim.cmd("normal! o")
        vim.api.nvim_win_set_cursor(0, { pos.end_row, pos.end_col - 1, })
    end)
end

-- setup
function M.setup(opts)
    log.probe("setup")
    setup_which_key()
    M.setup_vl(opts)
end

return M
