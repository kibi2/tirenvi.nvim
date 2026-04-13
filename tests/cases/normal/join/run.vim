source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
sleep 1m
execute "normal! 3G"
execute "normal! 3J"
sleep 1m
execute "normal! 7G"
execute "normal! 3gJ"
sleep 1m
execute "normal! 9G"
execute "normal! J"

call RunTest({})