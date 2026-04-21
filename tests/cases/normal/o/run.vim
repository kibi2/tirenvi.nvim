source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
execute "normal! 5Go\<Esc>"
sleep 1m
execute "normal! 3GOabc\<Esc>"
sleep 1m
execute "normal! 10Go 1 | 2\<Esc>"
sleep 1m
execute "normal! 9GoABC\<Esc>"
sleep 1m
execute "normal! 1Goiroha\<Esc>"
sleep 1m

call Snapshot({})

edit $TIRENVI_ROOT/tests/data/simple.csv
execute "normal! Onew line\<Esc>"
sleep 1m

call RunTest({})
