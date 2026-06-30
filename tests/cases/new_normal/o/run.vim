source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
            lua print(Debug.layout())

CASE o at Alice
	call At(2, 3, 1)
        normal! o
            sleep 1m | lua print(Debug.layout())

CASE Oabs at Top (header line)
	call At(2, 1, 3)
        normal! Oabc
            sleep 1m | lua print(Debug.layout())

CASE insert pipe at Bottom
	call At(2, 7, 2)
        normal! o 1 | 2
            sleep 1m | lua print(Debug.layout())

CASE insert ABC
	call At(2, 6, 1)
        normal! oABC
            sleep 1m | lua print(Debug.layout())

CASE insert iroha TOP
	call At(1, 1, 1)
        normal! oiroha
            sleep 1m | lua print(Debug.layout())

call Snapshot({ 'desc': 'GFM' })

" ===== GFM 3o =====

CASE 3O at top
e!
	call At(2, 1, 1)
        normal! 3O
            sleep 1m | lua print(Debug.layout())

CASE 3OQWE at top
	call At(2, 1, 1)
        normal! 3OQWE
            sleep 1m | lua print(Debug.layout())

CASE 3o at top
e!
	call At(2, 1, 1)
        normal! 3o
            sleep 1m | lua print(Debug.layout())

CASE 3oRTY at top
	call At(2, 1, 1)
        normal! 3oRTY
            sleep 1m | lua print(Debug.layout())

CASE 3o at bottom
	call At(3, 1, 1)
        normal! k3o
            sleep 1m | lua print(Debug.layout())

CASE 3oIOP at bottom
	call At(3, 1, 1)
        normal! k3oIOP
            sleep 1m | lua print(Debug.layout())

call Snapshot({ 'desc': 'GFM 3o' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs
lua print(Debug.layout())

CASE TOP O
	call At(1, 1, 1)
        normal! Onew line
            sleep 1m | lua print(Debug.layout())

CASE BOTTOM o
        normal! Go
            sleep 1m | lua print(Debug.layout())

call RunTest({ 'desc': 'CSV' })