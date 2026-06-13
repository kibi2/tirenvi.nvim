source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
Tir toggle
call cursor(1, 1)
execute "normal! a\<Tab>\<Esc>"

call RunTest({})