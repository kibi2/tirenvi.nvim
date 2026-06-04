" Overwrite and save
source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

execute 'edit ' . outfile
write
sleep 1m
execute "normal! 1G0x"

call RunTest({ 'file': outfile })