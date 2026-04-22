" Open a CSV file, save it immediately under a different name as a TSV, and verify the file contents.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.xxx'

edit $TIRENVI_ROOT/tests/data/complex.csv
execute 'write ' . outfile

call RunTest({ 'file': outfile, 'nomessage': 'true' })