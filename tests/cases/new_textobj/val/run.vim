source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  textobj = {
    column = "h"
  },
})
EOF

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs
lua Debug.goto(1, 1, 2)
lua print(Debug.layout())

CASE yank column and put
call feedkeys("vah", "x")
execute "normal! y"
execute "normal! $h"
execute "normal! p"
lua print(Debug.layout())

CASE yank 2column and put
lua Debug.goto(1, 7, 1)
execute "normal! l"
lua print(Debug.layout())
call feedkeys("v2ah", "x")
execute "normal! y"
execute "normal! P"
lua print(Debug.layout())

CASE repair disable
Tir repair disable
lua Debug.goto(1, 5, 1)
execute "normal! ainsert\<Esc>"
call feedkeys("vah", "x")

call Snapshot({ 'desc': 'CSV' })

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua Debug.goto(1, 1, 1)
lua print(Debug.layout())

CASE yank plain
call feedkeys("vah", "x")
execute "normal! y"
execute "normal! $h"
execute "normal! p"
lua print(Debug.layout())

CASE yank 2column and put
lua Debug.goto(2, 4, 2)
call feedkeys("v2ah", "x")
execute "normal! ly"
execute "normal! p"
lua print(Debug.layout())

call RunTest({ 'desc': 'GFM' })