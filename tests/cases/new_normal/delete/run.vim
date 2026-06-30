source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
lua print(Debug.layout())

CASE Fail table join
	call At(3, 1, 1)
        normal! dd
            sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'fail table join' })

CASE Delete Alice -> Ali
	call At(2, 3, 1)
        normal! 4lD
            sleep 1m | lua print(Debug.layout())

CASE Delete All (separate table)
	call At(4, 4, 1)
        normal! 0D
            sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'delete line data' })

CASE table join
	call At(4, 1, 1) | normal! $h
        call feedkeys("val", "x")
        normal! xkdd
            sleep 1m | lua print(Debug.layout())

CASE last record : grid -> plain
	call At(3, 1, 0) | normal! k0
        normal! D
            sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'table join' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE Delete columns
	call At(1, 1, 1)
        normal! 0D
            sleep 1m | lua print(Debug.layout())

CASE Delete All
	call At(1, 2, 2)
        normal! 2lD
            sleep 1m | lua print(Debug.layout())

call RunTest({'desc': 'CSV'})