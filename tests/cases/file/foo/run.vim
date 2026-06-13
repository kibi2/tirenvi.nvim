source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.foo'

edit $TIRENVI_ROOT/tests/data/simple.csv
execute 'file ' . outfile
write

call RunTest({ 'file': outfile })