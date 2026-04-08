" Verify the screen display after executing the Tir toggle command.
" Display in the tir-vim file format.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit $TIRENVI_ROOT/tests/data/complex.csv
Tir toggle
Tir toggle
Tir _hbar

call RunTest({})
