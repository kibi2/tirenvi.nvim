source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE 3J
lua Debug.goto(2, 1, 3)
execute "normal! 3J"
sleep 1m
lua print(Debug.layout())

CASE 2gJ
lua Debug.goto(2, 3, 2)
execute "normal! 2gJ"
sleep 1m
lua print(Debug.layout())

CASE J
lua Debug.goto(3, 1, 1)
execute "normal! kJ"
sleep 1m
lua print(Debug.layout())

call Snapshot({})

CASE Alice + Bob
e!
lua Debug.goto(2, 3, 1)
execute "normal! J"
sleep 1m
lua print(Debug.layout())

call RunTest({})