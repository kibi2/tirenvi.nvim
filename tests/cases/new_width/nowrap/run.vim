source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/table2.md

call Case("initial cached attrs")
lua print(Debug.cached_attrs("init //"))

call Case("width+ on first plain block")
lua Debug.goto(1, 1, 1)
lua print(Debug.cursor_pos())
Tir width+
lua print(Debug.cached_attrs("width+ //"))

call Case("width+3 on first grid block")
lua Debug.goto(2, 1, 1)
lua print(Debug.cursor_pos())
Tir width+3
lua print(Debug.cached_attrs("width+3 //"))

call Case("width-2 on second grid block, column 2")
lua Debug.goto(4, 2, 1)
execute "normal! " . luaeval("require('tirenvi.editor.motion').f()")
Tir width-2
lua print(Debug.cached_attrs("width-2 //"))

call RunTest({ 'desc': 'Tir width nowrap' })


sleep 1m
execute "normal! dd"
"                              5, 3, 11
execute "normal! 1j11l"
Tir width=8
call Snapshot({'desc': 'width = 5, 3, 8' })
execute "normal! 0gg2j6l"
Tir width=5
call Snapshot({'desc': 'width = 5, 5, 8' })
execute "normal! 0gg4j5l"
Tir width=9
echomsg "9,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              9, 5, 8
execute "normal! 0gg3j9l"
Tir width+9
echomsg "18,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              18, 5, 8
Tir width+5
echomsg "23,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              23, 5, 8
Tir width+
echomsg "24,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              24, 5, 8
call feedkeys("u", "x")
echomsg "23,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              23, 5, 8
execute "normal! 0gg6j6l"
Tir width-10
echomsg "13,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              13, 5, 8
execute "normal! 0gg8j1l"
Tir width=10
echomsg "13,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              13, 5, 8
execute "normal! 0gg3j$"
Tir width=20
echomsg "13,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              13, 5, 8
call cursor(2, 1)
Tir width-100
echomsg "2,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              2, 5, 8
call cursor(1, 1)
Tir width-
echomsg "2,5,8" b:tirenvi.attrs[1]
sleep 1m
"                              2, 5, 8
execute "normal! 0gg3j3l"
Tir width=
echomsg "2,3,8" b:tirenvi.attrs[1]
sleep 1m
"                              2, 3, 8
Tir width=x

call RunTest({ 'desc': 'width = 2, 3, 8' })
