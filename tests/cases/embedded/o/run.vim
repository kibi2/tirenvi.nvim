source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table.txt

CASE initial cached attrs
        Tir toggle
            sleep 1m | lua print(Debug.layout())

CASE o at grid top "o" new record
	call At(2, 1, 1)
        normal! oNew Reocrd
            sleep 1m | lua print(Debug.layout())

CASE o at grid top "O" new plain
	call At(2, 1, 1)
        normal! ONew plain
            sleep 1m | lua print(Debug.layout())

CASE o at grid top "o" new record
	call At(4, 1, 1)
        normal! oNew Reocrd
            sleep 1m | lua print(Debug.layout())

CASE o at grid top "O" new plain
	call At(4, 1, 1)
        normal! ONew plain
            sleep 1m | lua print(Debug.layout())

CASE o at grid top "empty" grid
	call At(6, 2, 1)
        normal! o
            sleep 1m | lua print(Debug.layout())

CASE o at grid top "empty" plain
	call At(6, 1, 1)
        normal! O
            sleep 1m | lua print(Debug.layout())

call Snapshot({ 'desc': 'CSV' })