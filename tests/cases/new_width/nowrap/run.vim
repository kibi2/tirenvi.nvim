source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
lua print(Debug.layout())

CASE wrap plain#1
lua Debug.goto(1, 1, 1)
Tir wrap
lua print(Debug.layout())

CASE wrap grid#1 nowrap -> +10
lua Debug.goto(2, 2, 1)
Tir width+10
lua print(Debug.layout())

CASE wrap grid#1 +10 -> nowrap
lua Debug.goto(2, 1, 1)
Tir wrap
lua print(Debug.layout())

CASE wrap grid#1 nowrap -> fit
Tir wrap
lua print(Debug.layout())

CASE wrap grid#2 -> auto
lua Debug.goto(4, 2, 3)
Tir wrap
lua print(Debug.layout())

CASE wrap grid#2 nowrap
lua Debug.goto(4, 3, 2)
Tir wrap
lua print(Debug.layout())

CASE wrap plain#2
lua Debug.goto(3, 1, 2)
Tir wrap
lua print(Debug.layout())

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV initial cached attrs
lua print(Debug.layout())

CASE CSV wrap -> fit
lua Debug.goto(1, 3, 2)
Tir wrap
lua print(Debug.layout())

CASE CSV wrap -> nowrap
lua Debug.goto(1, 6, 1)
Tir wrap
lua print(Debug.layout())

CASE wrap=3
lua Debug.goto(1, 2, 3)
Tir wrap=3
lua print(Debug.layout())

CASE wrap foo
lua Debug.goto(1, 2, 3)
Tir wrap foo
lua print(Debug.layout())

call RunTest({ 'desc': 'Tir wrap' })

" ===== CSV =====