source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv

lua << EOF
local log = require("tirenvi.util.log")
vim.api.nvim_win_set_cursor(0, {2, 0})
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

call RunTest({})