source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE o at Alice
lua Debug.goto(2, 3, 1)
execute "normal! o\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE Oabs at Top (header line)
lua Debug.goto(2, 1, 3)
execute "normal! Oabc\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE insert pipe at Bottom
lua Debug.goto(2, 7, 2)
execute "normal! o 1 | 2\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE insert ABC
lua Debug.goto(2, 6, 1)
execute "normal! oABC\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE insert iroha TOP
lua Debug.goto(1, 1, 1)
execute "normal! oiroha\<Esc>"
sleep 1m
lua print(Debug.layout())

call Snapshot({ 'desc': 'GFM' })

" ===== GFM 3o =====

CASE 3O at top
e!
lua Debug.goto(2, 1, 1)
execute "normal! 3O\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE 3OQWE at top
lua Debug.goto(2, 1, 1)
execute "normal! 3OQWE\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE 3o at top
e!
lua Debug.goto(2, 1, 1)
execute "normal! 3o\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE 3oRTY at top
lua Debug.goto(2, 1, 1)
execute "normal! 3oRTY\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE 3o at bottom
lua Debug.goto(3, 1, 1)
execute "normal! k3o\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE 3oIOP at bottom
lua Debug.goto(3, 1, 1)
execute "normal! k3oIOP\<Esc>"
sleep 1m
lua print(Debug.layout())

call Snapshot({ 'desc': 'GFM 3o' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs
lua print(Debug.layout())

CASE TOP O
lua Debug.goto(1, 1, 1)
execute "normal! Onew line\<Esc>"
sleep 1m
lua print(Debug.layout())

CASE BOTTOM o
execute "normal! Go\<Esc>"
sleep 1m
lua print(Debug.layout())

call RunTest({ 'desc': 'CSV' })