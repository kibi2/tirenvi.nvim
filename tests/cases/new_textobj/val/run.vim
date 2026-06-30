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
	call At(1, 1, 2)
      lua print(Debug.layout())

CASE yank column and put
    	call feedkeys("vah", "x")
    	normal! y
    	normal! $h
    	normal! p
			lua print(Debug.layout())

CASE yank 2column and put
	call At(1, 7, 1)
	normal! l
			lua print(Debug.layout())
    call feedkeys("v2ah", "x")
		normal! y
		normal! P
			lua print(Debug.layout())

CASE repair disable
Tir repair disable
	call At(1, 5, 1)
		normal! ainsert
    	call feedkeys("vah", "x")

call Snapshot({ 'desc': 'CSV' })

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
	call At(1, 1, 1)
			lua print(Debug.layout())

CASE yank plain
    call feedkeys("vah", "x")
		normal! y
		normal! $h
		normal! p
			lua print(Debug.layout())

CASE yank 2column and put
	call At(2, 4, 2)
    call feedkeys("v2ah", "x")
		normal! ly
		normal! p
			lua print(Debug.layout())

call RunTest({ 'desc': 'GFM' })