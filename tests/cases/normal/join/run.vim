source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
call cursor(1, 1)
execute "normal! yypJ"

redraw

call RunTest({})