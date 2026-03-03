" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
Tir toggle
call cursor(1, 1)
execute "normal! a\<Tab>\<Esc>"

call RunTest({})