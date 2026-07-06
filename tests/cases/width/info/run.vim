source $TIRENVI_ROOT/tests/common.vim

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/wide.csv

CASE initial cached attrs
            lua print(Debug.layout())

CASE width? CSV col#1
	call At(1, 1, 1)
		Tir width?

CASE width? CSV col#3
	call At(1, 4, 3)
		Tir width?

CASE width? CSV col#4
	call At(1, 10, 4)
		Tir width?

CASE width? CSV col#4 wrap
		Tir wrap
		Tir width?

CASE width? CSV col#10
	call At(1, 5, 10)
    normal! G
		Tir width?

CASE width? CSV col#$
    normal! $
		Tir width?

CASE width? CSV col#$
    normal! $
		Tir width+
		Tir width?

CASE width? CSV col#$
    normal! $
		Tir fit=40
		Tir width?

CASE width? CSV col#$
    normal! $
		Tir fit=
		Tir width?

CASE width? CSV toggle
		Tir toggle
		Tir width?

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial GFM cached attrs
            lua print(Debug.layout())

CASE width? GFM plain
	call At(1, 2, 1)
		Tir width?

CASE width? GFM grid
	call At(1, 3, 1)
		Tir width?

CASE width?9 invalid
	call At(1, 3, 1)
		Tir width?9

call Snapshot({ 'desc': 'Tir wrap' })