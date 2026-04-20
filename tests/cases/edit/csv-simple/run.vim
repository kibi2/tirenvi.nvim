source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit input.csv
execute 'write ' . outfile
wincmd s
wincmd c

call RunTest({ 'file': outfile })