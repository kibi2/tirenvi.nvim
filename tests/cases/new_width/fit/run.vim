source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
lua print(Debug.layout())

CASE fit+2 plain#1
lua Debug.goto(1, 1, 1)
Tir fit+2
lua print(Debug.layout())

CASE fit-4 grid#1
lua Debug.goto(2, 1, 1)
Tir fit-4
lua print(Debug.layout())

CASE fit - 10 grid#1
lua Debug.goto(2, 1, 1)
Tir fit - 10
lua print(Debug.layout())
Tir fit=

CASE fit+10 grid#1
lua Debug.goto(2, 4, 2)
Tir fit+10
lua print(Debug.layout())

CASE fit=80 grid#2
lua Debug.goto(4, 2, 3)
Tir fit=80
lua print(Debug.layout())

CASE fit=1 grid#2
lua Debug.goto(4, 3, 2)
Tir fit=1
lua print(Debug.layout())

CASE fit-10 plain#2
lua Debug.goto(3, 1, 2)
Tir fit-10
lua print(Debug.layout())

CASE fit - 10 gird#2
lua Debug.goto(4, 3, 2)
Tir fit - 10
lua print(Debug.layout())

CASE fit =200 grid#2
lua Debug.goto(2, 3, 2)
Tir fit =200
lua print(Debug.layout())

CASE fit!3
lua Debug.goto(3, 2, 3)
Tir fit!3
lua print(Debug.layout())

CASE fit foo
lua Debug.goto(1, 2, 3)
Tir fit foo
lua print(Debug.layout())

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV fit =100
Tir fit =100
lua print(Debug.layout())

CASE CSV fit+50
Tir fit+50
lua print(Debug.layout())

CASE CSV fit-100
Tir fit-100
lua print(Debug.layout())

call RunTest({ 'desc': 'Tir fit' })