source $TIRENVI_ROOT/tests/common.vim

" ===== CSV redraw=====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE delete(val) -> put
            lua print(Debug.layout())
	call At(1, 1, 1)
        call feedkeys("val", "x")
		normal! d
			sleep 1m | lua print(Debug.layout())
		normal! $P
			sleep 1m | lua print(Debug.layout())

CASE delete(val) -> redraw -> put
        e!
	call At(1, 7, 1) | normal! l
            lua print(Debug.layout())
        call feedkeys("val", "x")
		normal! x
			sleep 1m | lua print(Debug.layout())
        Tir repair
			sleep 1m | lua print(Debug.layout())
		normal! $P
			sleep 1m | lua print(Debug.layout())

call Snapshot({})

" ===== GFM repair toggle =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE repair off
        Tir repair toggle
	call At(2, 1, 1) | normal! h
		normal! 3D
        %s /o/QW/g
	call At(2, 1, 1)
		normal! 3yy
	call At(3, 1, 1)
		normal! p
			sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'before format' })

CASE redraw
        call Tir("redraw")

call Snapshot({'desc': 'after format' })

" ===== CSV repair toggle =====
edit input.csv

CASE repair on/off
		Tir repair disable
		Tir repair disable
		Tir repair enable
		Tir repair enable
		Tir repair of
		Tir repair toggle
		Tir repair toggle

CASE repair off -> redraw
	call At(1, 2, 1) | normal! h
		Tir repair disable
		normal! aADD
		Tir redraw
			sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'final' })

CASE repair off -> on
		Tir repair disable
        %s /[A-z]/xx/g
	call At(1, 2, 2) | normal! h
		normal! D
		call Tir("repair enable")
	call At(1, 2, 2)
		normal! Onew line
			sleep 1m | lua print(Debug.layout())

call Snapshot({})