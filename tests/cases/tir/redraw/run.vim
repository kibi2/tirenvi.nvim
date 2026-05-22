" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

edit input.csv
sleep 1m
Tir _repair off
sleep 1m
Tir _repair off
sleep 1m
Tir _repair on
sleep 1m
Tir _repair on
sleep 1m
Tir _repair of
sleep 1m
Tir _repair
sleep 1m
Tir _repair
sleep 1m
call cursor(2, 1)
execute "normal! aADD\<Esc>"
sleep 1m
Tir redraw
sleep 1m

call RunTest({})