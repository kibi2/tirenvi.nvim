source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
call cursor(2, 1)
call feedkeys("vil", "x")
execute "normal d"
call cursor(4, 15)
call feedkeys("vil", "x")
execute "normal d"
execute "normal 0"
execute "normal p"

call RunTest({})