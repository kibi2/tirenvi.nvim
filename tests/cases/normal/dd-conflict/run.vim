source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/table2.md
call cursor(7, 1)
execute "normal! dd\<Esc>"
sleep 1m
" execute "u"
" sleep 1m
" execute "normal! dd\<Esc>"

call RunTest({})