source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
execute "normal! 4j"
execute "normal! aADD \<Esc>"
sleep 1m
set filetype=bar
sleep 1m
execute "normal! jdd"

call RunTest({})