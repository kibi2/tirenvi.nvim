source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE yyp : grid last row
	call At(2, 6, 1)
        execute "normal! yyp"
            sleep 1m | lua print(Debug.layout())

CASE yyp : grid row "nipponbashi"
	call At(2, 5, 3)
        execute "normal! yyp"
            sleep 1m | lua print(Debug.layout())

CASE yyp : grid continue row
	call At(2, 4, 2)
        execute "normal! yyp"
            sleep 1m | lua print(Debug.layout())

CASE yyp : plain
	call At(1, 2, 1)
        execute "normal! yyp"
            sleep 1m | lua print(Debug.layout())

call RunTest({})