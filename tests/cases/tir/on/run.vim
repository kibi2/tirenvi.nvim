" Verify the screen display after executing the Tir toggle command.
" Display in the tir-vim file format.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit $TIRENVI_ROOT/tests/data/simple.md
sleep 1m
call cursor(2, 1)
Tir width-1
sleep 1m
call cursor(2, 10)
Tir width=5
sleep 1m
call cursor(2, 22)
Tir width+2
sleep 1m
Tir toggle
sleep 1m
Tir toggle
sleep 1m
Tir _hbar
sleep 1m

call RunTest({})
