source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/table2.md

call Case("initial cached attrs")
lua print(Debug.cached_attrs())

call Case("wrap plain#1")
lua Debug.goto(1, 1, 1)
lua print(Debug.cursor_pos())
Tir wrap
lua print(Debug.cached_attrs())

call Case("wrap grid#1")
lua Debug.goto(2, 1, 1)
lua print(Debug.cursor_pos())
Tir wrap
lua print(Debug.cached_attrs())

call Case("wrap grid#2")
lua Debug.goto(4, 2, 3)
Tir wrap
lua print(Debug.cached_attrs())

call Case("wrap grid#2 again")
lua Debug.goto(4, 3, 2)
Tir width=
lua print(Debug.cached_attrs())

call Case("wrap plain#2")
lua Debug.goto(3, 3, 2)
Tir wrap
lua print(Debug.cached_attrs())

" wrap fit60 wrap wrap でfit60が再現されるか？
call Case("wrap grid#1 again")
lua Debug.goto(2, 3, 2)
Tir wrap
lua print(Debug.cached_attrs())


call Case("wrap=3")
lua Debug.goto(4, 2, 3)
Tir wrap=3
lua print(Debug.cached_attrs())

call Case("wrap foo")
lua Debug.goto(1, 2, 3)
Tir width
lua print(Debug.cached_attrs())

call RunTest({ 'desc': 'Tir wrap' })

