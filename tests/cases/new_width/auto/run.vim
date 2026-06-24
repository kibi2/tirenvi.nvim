source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
lua print(Debug.layout())

CASE fit= plain#1
lua Debug.goto(1, 1, 1)
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1
lua Debug.goto(1, 2, 1)
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1
call feedkeys("vil", "x")
execute "normal! d"
Tir fit=
lua print(Debug.layout())

" ===== CSV =====

call RunTest({ 'desc': 'Tir wrap' })