source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE <expand tab>Alice
set expandtab
lua Debug.goto(2, 3, 1)
execute "normal! a\<Tab>\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE <expand tab> plain
set expandtab
lua Debug.goto(1, 2, 1)
execute "normal! a\<Tab>\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE <noexpand tab> plain
set noexpandtab
execute "normal! 02G10l"
" execute "normal! a\<Tab>\<Esc>"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_tab(0)
vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m
lua print(Debug.layout())

CASE <noexpand tab> Bob Age
set noexpandtab
lua Debug.goto(2, 4, 2)
execute "normal! l"
" execute "normal! a\<Tab>\<Esc>"
lua << EOF
local key = require("tirenvi.editor.commands").keymap_tab(0)
vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m
lua print(Debug.layout())

call Snapshot({ 'desc': 'GFM' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs
lua print(Debug.layout())

CASE <expand tab>Alice
set noexpandtab
lua Debug.goto(1, 2, 1)
" execute "normal! a\<Tab>\<Esc>"

lua << EOF
local log = require("tirenvi.util.log")
local key = require("tirenvi.editor.commands").keymap_tab(0)
for i = 1, #key do
  log.error(string.format("[CI] key = %02X", string.byte(key, i)))
end
vim.api.nvim_put({key}, "c", true, true)
EOF
sleep 1m
lua print(Debug.layout())

call Snapshot({ 'desc': 'CSV' })

" ===== FLAT =====

CASE <noexpand tab>FLAT
e!
set noexpandtab
Tir toggle
call cursor(1, 1)
execute "normal! a\<Tab>\<Esc>"

call RunTest({ 'desc': 'FLAT' })