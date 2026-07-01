source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
            lua print(Debug.layout())

CASE wrap plain#1
	call At(1, 1, 1)
		call Tir("wrap")

CASE wrap grid#1 nowrap -> +10
	call At(2, 2, 1)
        call Tir("width+10")

CASE wrap grid#1 +10 -> nowrap
	call At(2, 1, 1)
		call Tir("wrap")

CASE wrap grid#1 nowrap -> fit
		call Tir("wrap")

CASE wrap grid#2 -> auto
	call At(4, 2, 3)
		call Tir("wrap")

CASE wrap grid#2 nowrap
	call At(4, 3, 2)
		call Tir("wrap")

CASE wrap plain#2
	call At(3, 1, 2)
		call Tir("wrap")

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV initial cached attrs
            lua print(Debug.layout())

CASE CSV wrap -> fit
	call At(1, 3, 2)
		call Tir("wrap")

CASE CSV wrap -> nowrap
	call At(1, 6, 1)
		call Tir("wrap")

CASE wrap=3
	call At(1, 2, 3)
        call Tir("wrap=3")

CASE wrap foo
	call At(1, 2, 3)
        call Tir("wrap foo")

call Snapshot({ 'desc': 'Tir wrap' })

" ===== CSV =====