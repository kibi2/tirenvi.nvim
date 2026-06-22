source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs"
lua print(Debug.layout())

CASE wrap plain#1"
lua Debug.goto(1, 1, 1)
Tir wrap
lua print(Debug.layout())

CASE wrap grid#1"
lua Debug.goto(2, 1, 1)
Tir wrap
lua print(Debug.layout())

CASE wrap grid#2"
lua Debug.goto(4, 2, 3)
Tir wrap
lua print(Debug.layout())

CASE wrap grid#2 again"
lua Debug.goto(4, 3, 2)
Tir wrap
lua print(Debug.layout())

CASE wrap plain#2"
lua Debug.goto(3, 3, 2)
Tir wrap
lua print(Debug.layout())

" wrap fit60 wrap wrap でfit60が再現されるか？
CASE wrap grid#1 again"
lua Debug.goto(2, 3, 2)
Tir wrap
lua print(Debug.layout())

CASE wrap=3"
lua Debug.goto(4, 2, 3)
Tir wrap=3
lua print(Debug.layout())

CASE wrap foo"
lua Debug.goto(1, 2, 3)
Tir wrap foo
lua print(Debug.layout())

call RunTest({ 'desc': 'Tir wrap' })
