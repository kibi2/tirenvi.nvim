source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE yyp : grid last row
lua Debug.goto(2, 6, 1)
execute "normal! yyp"
sleep 1m
lua print(Debug.layout())

CASE yyp : grid row "nipponbashi"
lua Debug.goto(2, 5, 3)
execute "normal! yyp"
sleep 1m
lua print(Debug.layout())

CASE yyp : grid continue row
lua Debug.goto(2, 4, 2)
execute "normal! yyp"
sleep 1m
lua print(Debug.layout())

CASE yyp : plain
lua Debug.goto(1, 2, 1)
execute "normal! yyp"
sleep 1m
lua print(Debug.layout())

call RunTest({})