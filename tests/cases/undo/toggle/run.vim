source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit $TIRENVI_ROOT/tests/data/simple.csv
sleep 1m
Tir toggle
sleep 1m
Tir toggle
sleep 1m
u
sleep 1m
echomsg b:tirenvi.flat
sleep 1m
execute "normal! 1G2lD"

call RunTest({})
