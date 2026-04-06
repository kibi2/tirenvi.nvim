" Add an extension to a file without an extension using the file command.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit $TIRENVI_ROOT/tests/data/simple.csv
execute 'file ' . outfile
write
execute 'edit ' . outfile

call RunTest({ 'file': outfile })