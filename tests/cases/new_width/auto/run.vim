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

CASE fit= grid#1 logic A // within screen width: recommended width for an empty column is 3
call feedkeys("vil", "x")
execute "normal! d"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for a 3-character column is 4
execute "normal! 3aO\<Esc>"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for a 4-character column is 6
execute "normal! 0aP\<Esc>"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for an 18-character column is 24
execute "normal! j018aQ\<Esc>"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for a 19-character column is 25
execute "normal! 0aR\<Esc>"
Tir fit=
lua print(Debug.layout())

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/wide.csv

CASE wide CSV initial
lua print(Debug.layout())

CASE fit= logic C // exceeds screen width
Tir fit=
lua print(Debug.layout())

CASE fit= logic B // fits within screen width
call feedkeys("val", "x")
execute "normal! d"
Tir fit=
lua print(Debug.layout())

call RunTest({ 'desc': 'Tir wrap' })