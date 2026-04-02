source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  textobj = {
    column = "h"
  },
})
EOF

edit $TIRENVI_ROOT/tests/data/simple.md
call cursor(6, 12)
call feedkeys("vah", "x")
execute "normal y"
execute "normal $"
execute "normal P"

call RunTest({})