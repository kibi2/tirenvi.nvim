source $TIRENVI_ROOT/tests/common.vim

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv
	call At(1, 1, 1)

CASE initial cached attrs
			lua print(Debug.layout())

CASE nowrap -> wrap
		call Tir("wrap")

CASE nowrap -> wrap
		call Tir("wrap")

call Snapshot({ 'desc': 'change wrap mode' })