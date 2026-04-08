source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
call cursor(7, 1)
execute "normal! yyp\<Esc>"
sleep 1m
call cursor(6, 1)
execute "normal! yyp\<Esc>"
sleep 1m
call cursor(5, 1)
execute "normal! yyp\<Esc>"
sleep 1m

call RunTest({})