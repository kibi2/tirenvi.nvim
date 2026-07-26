source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md

" ===== EMBEDDED =====
    set ft=bar
    4,10s/^/ # #  /g
    normal! 4G
	Tir toggle

CASE embedded -> At(2,3,3) (2,5,1) (2,4,2) (2,2,3)
	call At(2, 3, 3)
            sleep 1m | lua print(Debug.layout())
	call At(2, 5, 1)
        Tir width+
            sleep 1m | lua print(Debug.layout())
	call At(2, 4, 2)
        Tir width=10
            sleep 1m | lua print(Debug.layout())
	call At(2, 2, 3)
        Tir width-
            sleep 1m | lua print(Debug.layout())

call Snapshot({ 'desc': 'simple md -> tir' })
