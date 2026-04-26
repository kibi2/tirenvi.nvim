" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
set expandtab
call cursor(5, 1)
execute "normal! a\<Tab>\<Esc>"
sleep 1m
call cursor(2, 1)
execute "normal! a\<Tab>\<Esc>"
sleep 1m
set noexpandtab
execute "normal! 2G10la\<Tab>\<Esc>"
sleep 1m
execute "normal! 6G10la\<Tab>\<Esc>"
sleep 1m

call RunTest({})