" Open a CSV file, save it immediately under a different name as a TSV, and verify the file contents.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.tsv'

edit $TIRENVI_ROOT/tests/data/simple.csv
execute 'write ' . outfile

call RunTest({ 'file': outfile })