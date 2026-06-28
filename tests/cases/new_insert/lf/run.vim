source $TIRENVI_ROOT/tests/common.vim

lua << EOF
log = require("tirenvi.util.log")
EOF

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE lf-at-start <lf>|2-1|2-2|2-3|
lua Debug.goto(1, 2, 1)
execute "normal! 0"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_lf(0)
for i = 1, #key do
  log.error(string.format("[CI] key = %02X", string.byte(key, i)))
end
if key == "\n" or key == "\r" then
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, {""})
else
  vim.api.nvim_put({key}, "c", true, true)
end
EOF
lua print(Debug.layout())
call Snapshot({})

CASE lf-in-cell |<lf char>2-1|2-2|2-3|
e!
lua Debug.goto(1, 2, 1)
lua << EOF
-- vim.api.nvim_win_set_cursor(0, {2, 2})
local key = require("tirenvi.editor.commands").keymap_lf(0)
for i = 1, #key do
  log.error(string.format("[CI] key = %02X", string.byte(key, i)))
end
if key == "\n" or key == "\r" then
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, {""})
else
  vim.api.nvim_put({key}, "c", true, true)
end
EOF
lua print(Debug.layout())

call Snapshot({})

CASE lf-in-flat
e!
Tir toggle
lua << EOF
vim.api.nvim_win_set_cursor(0, {2, 1})
local key = require("tirenvi.editor.commands").keymap_lf(0)
local line = {"[CI] key = "}
for i = 1, #key do
  table.insert(line, string.format("%02X", string.byte(key, i)))
end
if key == "\n" or key == "\r" then
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, {table.concat(line, "")})
end
EOF

call RunTest({})