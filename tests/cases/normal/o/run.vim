source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
call cursor(2, 2)
execute "normal! o\<Esc>"
sleep 1m
call cursor(1, 5)
execute "normal! O abc\<Esc>"
sleep 1m
execute "normal! Go 1 | 2\<Esc>"
sleep 1m

call RunTest({})
