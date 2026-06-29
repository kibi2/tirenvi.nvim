source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE nowrap mode : toggle -> toggle
lua print(Debug.layout())
Tir toggle
Tir toggle
sleep 1m
lua print(Debug.layout())

CASE wrap mode : toggle -> toggle
lua Debug.goto(2, 3, 2)
Tir width=3
lua Debug.goto(4, 5, 3)
Tir fit=13
lua Debug.goto(1, 1, 1)
sleep 1m
lua print(Debug.layout())
Tir toggle
Tir toggle
lua Debug.goto(1, 1, 1)
sleep 1m
lua print(Debug.layout())

lua Debug.goto(1, 1, 1)
execute "normal! 0gg2j0"
Tir width-1
sleep 1m
execute "normal! 0gg4j6l"
Tir width=5
sleep 1m
execute "normal! 0gg7j22l"
Tir width+2
sleep 1m
Tir toggle
sleep 1m
Tir toggle
sleep 1m
call Snapshot({'desc': 'simple.md' })

" ===== GFM table 0 =====
CASE table 0
edit $TIRENVI_ROOT/tests/data/table0.md
Tir toggle
sleep 1m
lua print(Debug.layout())

" ===== NG case =====
CASE NG case
Tir
Tir bar
Tir toggle=
Tir repair
Tir reconcile
lua print(Debug.layout())

call RunTest({'desc': 'toggle' })
