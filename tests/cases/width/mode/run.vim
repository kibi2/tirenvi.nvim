source $TIRENVI_ROOT/tests/common.vim

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv
	call At(1, 1, 1)

CASE initial cached attrs
			lua print(Debug.layout())

CASE nowrap -> wrap (auto)
		call Tir("wrap")
		call Tir("wrap")
		call Tir("wrap")

CASE nowrap -> wrap (width)
		e!
			lua print(Debug.layout())
		call Tir("width+")
		call Tir("wrap")
		call Tir("wrap")

CASE nowrap -> wrap (fit)
		e!
		call Tir("fit-")
		call Tir("wrap")
		call Tir("wrap")

CASE nowrap -> auto -> width -> fit -> auto
		e!
		call Tir("fit=")
		call Tir("width=")
		call Tir("fit=20")
		call Tir("fit=")

CASE nowrap -> fit -> width -> auto -> fit
		e!
		call Tir("fit=30")
		call Tir("width-2")
		call Tir("fit=")
		call Tir("fit+3")

call Snapshot({ 'desc': 'change wrap mode' })