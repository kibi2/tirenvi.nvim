source $TIRENVI_ROOT/tests/common.vim

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/wide.csv

CASE initial cached attrs
lua print(Debug.layout())

CASE width? CSV col#1
lua Debug.goto(1, 1, 1)
Tir width?

CASE width? CSV col#3
lua Debug.goto(1, 4, 3)
Tir width?

CASE width? CSV col#4
lua Debug.goto(1, 10, 4)
Tir width?

CASE width? CSV col#4 wrap
Tir wrap
Tir width?

CASE width? CSV col#10
lua Debug.goto(1, 5, 10)
execute "normal! G"
Tir width?

CASE width? CSV col#$
execute "normal! $"
Tir width?

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE width? plain
lua Debug.goto(1, 2, 1)
Tir width?

CASE width? grid
lua Debug.goto(1, 3, 1)
Tir width?

CASE width?9 invalid
lua Debug.goto(1, 3, 1)
Tir width?9

call RunTest({ 'desc': 'Tir wrap' })