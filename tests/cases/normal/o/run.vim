source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
call cursor(1, 1)
execute "normal! o123\<Esc>"
call cursor(0, 1)
execute "normal! O abc\<Esc>"
execute "normal! Go 1 | 2\<Esc>"
Tir redraw

call RunTest({})