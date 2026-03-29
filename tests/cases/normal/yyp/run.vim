source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
call cursor(6, 1)
execute "normal! yyp\<Esc>"

call RunTest({})