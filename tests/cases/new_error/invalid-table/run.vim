" Destructive operations on the table display an error and perform an undo.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
call cursor(6, 0)
execute "normal! x"

call RunTest({})