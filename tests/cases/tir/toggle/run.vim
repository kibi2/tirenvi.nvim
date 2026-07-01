source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE nowrap mode : toggle -> toggle
            lua print(Debug.layout())
        Tir toggle
        Tir toggle
            sleep 1m | lua print(Debug.layout())

CASE wrap mode : toggle -> toggle
	call At(2, 3, 2)
        Tir width=3
	call At(4, 5, 3)
        Tir fit=13
	call At(1, 1, 1)
            sleep 1m | lua print(Debug.layout())
        Tir toggle
        Tir toggle
	call At(1, 1, 1)
            sleep 1m | lua print(Debug.layout())

edit $TIRENVI_ROOT/tests/data/simple.md
	call At(2, 2, 1)
        Tir width-1
	call At(2, 3, 2)
        Tir width=5
	call At(2, 4, 3)
        Tir width+2
        Tir toggle
        Tir toggle

call Snapshot({'desc': 'simple.md' })

" ===== GFM table 0 =====
CASE table 0
edit $TIRENVI_ROOT/tests/data/table0.md
        Tir toggle
            sleep 1m | lua print(Debug.layout())

" ===== NG case =====
CASE NG case
        Tir
        Tir bar
        Tir toggle=
        Tir repair
        Tir reconcile
            lua print(Debug.layout())

call Snapshot({'desc': 'toggle' })
