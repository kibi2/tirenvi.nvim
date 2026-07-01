source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
lua print(Debug.layout())

CASE 3J
	call At(2, 1, 3)
        normal! 3J
            sleep 1m | lua print(Debug.layout())

CASE 2gJ
	call At(2, 3, 2)
        normal! 2gJ
            sleep 1m | lua print(Debug.layout())

CASE J
	call At(3, 1, 1)
        normal! kJ
            sleep 1m | lua print(Debug.layout())

call Snapshot({})

CASE Alice + Bob
e!
	call At(2, 3, 1)
        normal! J
            sleep 1m | lua print(Debug.layout())

call Snapshot({})