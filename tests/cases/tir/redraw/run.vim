source $TIRENVI_ROOT/tests/common.vim

" ===== CSV redraw=====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE delete(val) -> put
lua print(Debug.layout())
lua Debug.goto(1, 1, 1)
call feedkeys("val", "x")
execute "normal! d"
sleep 1m
lua print(Debug.layout())
execute "normal! $P"
sleep 1m
lua print(Debug.layout())
call Snapshot({})

CASE delete(val) -> redraw -> put
e!
lua print(Debug.layout())
lua Debug.goto(1, 1, 1)
call feedkeys("val", "x")
execute "normal! d"
sleep 1m
lua print(Debug.layout())
Tir redraw
sleep 1m
lua print(Debug.layout())
execute "normal! $P"
sleep 1m
lua print(Debug.layout())
call Snapshot({})

" ===== GFM repair toggle =====
edit $TIRENVI_ROOT/tests/data/simple.md

Tir repair toggle
sleep 1m
execute "normal! 3G"
execute "normal! 3D"
sleep 1m
%s /o/QW/g
sleep 1m
execute "normal! 3G"
execute "normal! 3yy"
execute "normal! 6G"
execute "normal! p"
sleep 1m
lua print(Debug.layout())

call Snapshot({'desc': 'before format' })

Tir repair
sleep 1m
lua print(Debug.layout())

call Snapshot({'desc': 'after format' })

" ===== CSV repair toggle =====
edit input.csv

Tir repair disable
Tir repair disable
Tir repair enable
Tir repair enable
Tir repair of
Tir repair toggle
Tir repair toggle
call cursor(2, 1)
execute "normal! aADD\<Esc>"
Tir repair
sleep 1m
lua print(Debug.layout())
call Snapshot({'desc': 'final' })

Tir repair disable
%s /[A-z]/xx/g
execute "normal! 3G2lD"
Tir repair enable
sleep 1m
call Snapshot({'desc': 'final' })

execute "normal! 2G"
execute "normal! Onew line\<Esc>"
sleep 1m
call Snapshot({'desc': 'final' })

call RunTest({})