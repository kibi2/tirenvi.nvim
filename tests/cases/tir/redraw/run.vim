" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

edit input.csv
sleep 1m
Tir _auto-reconcile off
sleep 1m
Tir _auto-reconcile off
sleep 1m
Tir _auto-reconcile on
sleep 1m
Tir _auto-reconcile on
sleep 1m
Tir _auto-reconcile of
sleep 1m
Tir _auto-reconcile
sleep 1m
Tir _auto-reconcile
sleep 1m
call cursor(2, 1)
execute "normal! aADD\<Esc>"
sleep 1m
Tir redraw
sleep 1m

call RunTest({})