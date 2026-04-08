source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
call cursor(2, 1)
call feedkeys("vil", "x")
execute "normal d"
sleep 1m
call cursor(4, 18)
call feedkeys("vil", "x")
execute "normal d"
sleep 1m
execute "normal 0"
sleep 1m
execute "normal p"
sleep 1m

call RunTest({})