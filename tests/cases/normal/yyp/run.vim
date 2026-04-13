source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
execute "normal! 0gg7j0"
execute "normal! yyp\<Esc>"
sleep 1m
execute "normal! 0gg6j0"
execute "normal! yyp\<Esc>"
sleep 1m
execute "normal! 0gg5j0"
execute "normal! yyp\<Esc>"
sleep 1m

call RunTest({})