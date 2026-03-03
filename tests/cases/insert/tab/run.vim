" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
set noexpandtab
" call cursor(2, 1)
" execute "normal! a\<Tab>\<Esc>"

lua << EOF
local log = require("tirenvi.util.log")
vim.api.nvim_win_set_cursor(0, {2, 0})
local key = require("tirenvi.editor.commands").keymap_tab(0)
for i = 1, #key do
  log.error(string.format("[CI] key = %02X", string.byte(key, i)))
end
vim.api.nvim_put({key}, "c", true, true)
EOF

call RunTest({})