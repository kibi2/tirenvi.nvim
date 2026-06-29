source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
lua print(Debug.layout())

CASE Fail table join
lua Debug.goto(3, 1, 1)
execute "normal! dd"
sleep 1m
lua print(Debug.layout())

call Snapshot({'desc': 'fail table join' })

CASE Delete Alice -> Ali
lua Debug.goto(2, 3, 1)
execute "normal! 4lD"
sleep 1m
lua print(Debug.layout())

CASE Delete All (separate table)
lua Debug.goto(4, 4, 1)
execute "normal! 0D"
sleep 1m
lua print(Debug.layout())

call Snapshot({'desc': 'delete line data' })

CASE table join
lua Debug.goto(4, 1, 1)
execute "normal! $h"
call feedkeys("val", "x")
execute "normal! xkdd"
sleep 1m
lua print(Debug.layout())

CASE last record : grid -> plain
lua Debug.goto(3, 1, 0)
execute "normal! k0"
execute "normal! D"
sleep 1m
lua print(Debug.layout())

call Snapshot({'desc': 'table join' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE Delete columns
lua Debug.goto(1, 1, 1)
execute "normal! 0D"
sleep 1m
lua print(Debug.layout())

CASE Delete All
lua Debug.goto(1, 2, 2)
execute "normal! 2lD"
sleep 1m
lua print(Debug.layout())

call RunTest({'desc': 'CSV'})