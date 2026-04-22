" Overwrite and save
source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

execute 'edit ' . outfile
write

call RunTest({ 'file': outfile, 'nomessage': 'true' })