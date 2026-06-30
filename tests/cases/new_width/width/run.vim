source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
            lua print(Debug.layout())

CASE width+ on first plain block"
    call At(1, 1, 1)
        call Tir("width+")

CASE width+3 on first grid block"
	call At(2, 1, 1)
		call Tir("width+3")

CASE width-2 on second grid block, column 2"
	call At(4, 2, 1) | execute "normal! " . luaeval("require('tirenvi.editor.motion').f()")
		call Tir("width-2")

CASE width=10 on second grid block, column 2"
	call At(4, 2, 2)
		call Tir("width=10")

CASE width= on second grid block, column 2"
	call At(4, 2, 2)
		call Tir("width=")

CASE width- on second grid block, column 3"
	call At(4, 2, 3)
		call Tir("width-")

CASE width on second grid block, column 3"
	call At(4, 2, 3)
		Tir width
		call Tir("width=x")

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs"
            lua print(Debug.layout())

CASE width+ on only one grid block"
	call At(1, 1, 1)
		call Tir("width+")

CASE width=20 on only one grid block"
	call At(1, 3, 3)
		call Tir("width=20")

CASE undo
        u
            lua print(Debug.layout())

CASE undo #2
        undo
            lua print(Debug.layout())

CASE undo #3
        undo
            lua print(Debug.layout())

CASE redo
        redo
            lua print(Debug.layout())

call RunTest({ 'desc': 'Tir width nowrap' })