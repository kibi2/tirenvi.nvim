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

CASE fit= grid#1 logic A 画面サイズ以下: 空の列の推奨幅は3
call feedkeys("vil", "x")
execute "normal! d"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A 画面サイズ以下: 3文字の列の推奨幅は4
execute "normal! 3aO\<Esc>"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A 画面サイズ以下: 4文字の列の推奨幅は6
execute "normal! 0aP\<Esc>"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A 画面サイズ以下: 18文字の列の推奨幅は24
execute "normal! j018aQ\<Esc>"
Tir fit=
lua print(Debug.layout())

CASE fit= grid#1 logic A 画面サイズ以下: 19文字の列の推奨幅は25
execute "normal! 0aR\<Esc>"
Tir fit=
lua print(Debug.layout())

" ===== CSV =====

call RunTest({ 'desc': 'Tir wrap' })