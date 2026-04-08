" Open a CSV file, save it immediately under a different name, and verify the file contents.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

lua << EOF
local M = require("tirenvi")
M.setup({
  textobj = {
    column = "h"
  },
})
EOF

edit $TIRENVI_ROOT/tests/data/simple.csv
sleep 1m
call cursor(2, 11)
Tir width=8
sleep 1m
execute 'write ' . outfile

call RunTest({ 'file': outfile })