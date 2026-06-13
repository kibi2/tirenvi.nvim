source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
set expandtab
execute "normal! 05G"
execute "normal! a\<Tab>\<Esc>"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_tab(0)
-- vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m

execute "normal! 02G"
execute "normal! a\<Tab>\<Esc>"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_tab(0)
-- vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m

set noexpandtab
execute "normal! 02G10l"
" execute "normal! a\<Tab>\<Esc>"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_tab(0)
vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m

execute "normal! 06G10l"
" execute "normal! a\<Tab>\<Esc>"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_tab(0)
vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m

call RunTest({})