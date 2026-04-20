" Verify the screen display after executing the Tir toggle command.
" Display in the tir-vim file format.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit $TIRENVI_ROOT/tests/data/simple.md
sleep 1m
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

call RunTest({})
