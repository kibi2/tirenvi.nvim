source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

call Case("block#2 bottom")
lua Debug.goto(2, 1, 1)
lua require('tirenvi').motion.block_bottom()
lua print(Debug.cursor_pos())

call Case("block#2 top")
lua require('tirenvi').motion.block_top()
lua print(Debug.cursor_pos())

call Case("next cell")
execute "normal! " . luaeval("require('tirenvi.editor.motion').f()")
lua print(Debug.cursor_pos())

call Case("next 2cell")
execute "normal! 2" . luaeval("require('tirenvi.editor.motion').f()")
lua print(Debug.cursor_pos())

call Case("prev 2cell")
execute "normal! 2" . luaeval("require('tirenvi.editor.motion').F()")
lua print(Debug.cursor_pos())

call Case("next cell")
lua Debug.goto(2, 4, 1)
execute "normal! " . luaeval("require('tirenvi.editor.motion').t()")
lua print(Debug.cursor_pos())

call Case("repeat 3cell")
execute "normal! 3;"
lua print(Debug.cursor_pos())

call Case("prev cell")
execute "normal! " . luaeval("require('tirenvi.editor.motion').T()")
lua print(Debug.cursor_pos())

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

call Case("CSV bottom")
lua require('tirenvi').motion.block_bottom()
execute "normal! " . luaeval("require('tirenvi.editor.motion').t()")
execute "normal! 2;"
lua print(Debug.cursor_pos())

call Case("CSV top")
lua require('tirenvi').motion.block_top()
lua print(Debug.cursor_pos())

call RunTest({ 'desc': 'motion f F t T g G' })
