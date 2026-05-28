source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/table2.md
execute "normal! 7G"
execute "normal! dd\<Esc>"
call Snapshot({'desc': 'fail table join' })

sleep 1m
" execute "u"
" sleep 1m
" execute "normal! dd\<Esc>"
execute "normal! 4G4l"
execute "normal! D\<Esc>"
sleep 1m
execute "normal! 11G0"
execute "normal! D\<Esc>"
sleep 1m

call RunTest({})