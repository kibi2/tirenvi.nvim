source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial
	call At(2, 1, 3)
            lua print(Debug.layout())

CASE block#2 bottom
        lua require('tirenvi').motion.block_bottom()
            lua print(Debug.layout())

CASE block#2 top
        lua require('tirenvi').motion.block_top()
            lua print(Debug.layout())

CASE next cell
	call At(2, 1, 1)
        execute "normal! " . luaeval("require('tirenvi.editor.motion').f()")
            lua print(Debug.layout())

CASE next 2cell
        execute "normal! 2" . luaeval("require('tirenvi.editor.motion').f()")
            lua print(Debug.layout())

CASE prev 2cell
        execute "normal! 2" . luaeval("require('tirenvi.editor.motion').F()")
            lua print(Debug.layout())

CASE next cell
	call At(2, 4, 1)
        execute "normal! " . luaeval("require('tirenvi.editor.motion').t()")
            lua print(Debug.layout())

CASE repeat 3cell
        normal! 3;
            lua print(Debug.layout())

CASE prev cell
        execute "normal! " . luaeval("require('tirenvi.editor.motion').T()")
            lua print(Debug.layout())

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV bottom
lua require('tirenvi').motion.block_bottom()
        execute "normal! " . luaeval("require('tirenvi.editor.motion').t()")
        normal! 2;
            lua print(Debug.layout())

CASE CSV top
        lua require('tirenvi').motion.block_top()
            lua print(Debug.layout())

call Snapshot({ 'desc': 'motion f F t T g G' })
