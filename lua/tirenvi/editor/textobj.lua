local config = require("tirenvi.config")
local log = require("tirenvi.util.log")

local M = {}

function M.select_column2()
    log.probe("select_column")
    local mode = vim.fn.mode()
    log.probe(mode)

    local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
    local col = col0 + 1
    local line = vim.api.nvim_get_current_line()
    log.probe({ row, col, line })

    local pipes = {}
    local leng = #config.marks.pipe
    log.probe(leng)
    for ichar = 1, #line do
        if line:sub(ichar, ichar + leng - 1) == config.marks.pipe then
            table.insert(pipes, ichar)
        end
    end
    log.probe(pipes)

    local col_idx
    for index = 1, #pipes - 1 do
        if col >= pipes[index] and col < pipes[index + 1] then
            col_idx = index
            break
        end
    end
    log.probe(col_idx)
    if not col_idx then return end

    local start_col = pipes[col_idx] + leng - 1
    local end_col   = pipes[col_idx + 1] - 2

    if mode == "n" then
        vim.api.nvim_win_set_cursor(0, { row, start_col })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { row, end_col })
    elseif mode == "v" or mode == "V" or mode == "\22" then
        log.probe({ start_col, end_col })
        vim.api.nvim_win_set_cursor(0, { row, start_col })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { row, end_col })
    end
end

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

local function get_select()
    log.probe("get_select")
    return {
        start_row = 2,
        end_row   = 3,
        start_col = 3,
        end_col   = 5,
    }
end

-- setup
function M.setup(opts)
    log.probe("setup")
    setup_which_key()
    vim.keymap.set("x", "il", function()
        local pos = get_select()

        vim.api.nvim_win_set_cursor(0, {
            pos.start_row,
            pos.start_col - 1,
        })

        vim.api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
        vim.cmd("normal! o")

        vim.api.nvim_win_set_cursor(0, {
            pos.end_row,
            pos.end_col - 1,
        })
    end)
end

return M
