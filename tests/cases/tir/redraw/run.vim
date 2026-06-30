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

call Snapshot({})

CASE delete(val) -> redraw -> put
        e!
            lua print(Debug.layout())
	call At(1, 1, 1)
        call feedkeys("val", "x")
		normal! d
			sleep 1m | lua print(Debug.layout())
        Tir repair
			sleep 1m | lua print(Debug.layout())
		normal! $P
			sleep 1m | lua print(Debug.layout())

call Snapshot({})

" ===== GFM repair toggle =====
edit $TIRENVI_ROOT/tests/data/simple.md

        Tir repair toggle
	normal! 3G
		normal! 3D
        %s /o/QW/g
	normal! 3G
		normal! 3yy
	normal! 6G
		normal! p
			sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'before format' })

        call Tir("redraw")

call Snapshot({'desc': 'after format' })

" ===== CSV repair toggle =====
edit input.csv

		Tir repair disable
		Tir repair disable
		Tir repair enable
		Tir repair enable
		Tir repair of
		Tir repair toggle
		Tir repair toggle
call cursor(2, 1)
		normal! aADD
		Tir redraw
			sleep 1m | lua print(Debug.layout())

call Snapshot({'desc': 'final' })

		Tir repair disable
%s /[A-z]/xx/g
	    normal! 3G2lD
		call Tir("repair enable")
	normal! 2G
		normal! Onew line
			sleep 1m | lua print(Debug.layout())

call RunTest({})