source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs"
lua print(Debug.layout(""))

CASE width+ on first plain block"
lua Debug.goto(1, 1, 1)
Tir width+
lua print(Debug.layout())

CASE width+3 on first grid block"
lua Debug.goto(2, 1, 1)
Tir width+3
lua print(Debug.layout())

CASE width-2 on second grid block, column 2"
lua Debug.goto(4, 2, 1)
execute "normal! " . luaeval("require('tirenvi.editor.motion').f()")
Tir width-2
lua print(Debug.layout())

CASE width=10 on second grid block, column 2"
lua Debug.goto(4, 2, 2)
Tir width=10
lua print(Debug.layout())

CASE width= on second grid block, column 2"
lua Debug.goto(4, 2, 2)
Tir width=
lua print(Debug.layout())

CASE width- on second grid block, column 3"
lua Debug.goto(4, 2, 3)
Tir width-
lua print(Debug.layout())

CASE width on second grid block, column 3"
lua Debug.goto(4, 2, 3)
Tir width
lua print(Debug.layout())

Tir width=x

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs"
lua print(Debug.layout())

CASE width+ on only one grid block"
lua Debug.goto(1, 1, 1)
Tir width+
lua print(Debug.layout())

CASE width=20 on only one grid block"
lua Debug.goto(1, 3, 3)
Tir width=20
lua print(Debug.layout())

CASE undo"
u
lua print(Debug.layout())

CASE undo #2"
undo
lua print(Debug.layout())

CASE undo #3"
undo
lua print(Debug.layout())

CASE redo"
redo
lua print(Debug.layout())

call RunTest({ 'desc': 'Tir width nowrap' })