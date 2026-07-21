local fn = vim.fn -- Neovim
local bo = vim.bo

local config = require("tirenvi.config")          -- Root

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser

local buffer = require("tirenvi.io.buffer")       -- IO
local buf_state = require("tirenvi.io.buf_state") -- IO
local reader = require("tirenvi.io.reader")

local util = require("tirenvi.util.util") -- Util
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}


-- =============================================================================
-- Public API

---@param ctx Context
function M.insert_char_in_newline(ctx)
    local cursor = reader.cursor(ctx)
    local row_cur = cursor.row_cur
    local line_new = buffer.get_line(ctx.bufnr, row_cur)
    if line_new ~= "" then
        return
    end
    local line_prev, line_next = buffer.get_lines_around(ctx.bufnr, Range.from_lua(row_cur, row_cur))
    local line_ref = line_prev
    if not buf_state.is_allow_plain(ctx.bufnr) then
        line_ref = line_ref or line_next
    end
    local pipe = tir_buf.get_pipe_char(line_ref)
    if not pipe then
        return
    end
    vim.v.char = pipe .. vim.v.char
end

---@return string
function M.keymap_lf()
    local col = fn.col(".")
    local line = fn.getline(".")
    if not tir_buf.get_pipe_char(line) then
        return util.get_termcodes("<CR>")
    end
    if col == 1 or col > #line then
        return util.get_termcodes("<CR>")
    end
    return config.marks.lf
end

---@return string
function M.keymap_tab()
    local line = fn.getline(".")
    if not tir_buf.get_pipe_char(line) then
        return util.get_termcodes("<Tab>")
    end
    if bo.expandtab then
        return util.get_termcodes("<Tab>")
    end
    return config.marks.tab
end

return M
