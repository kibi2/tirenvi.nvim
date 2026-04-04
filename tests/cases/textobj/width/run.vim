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
call cursor(2, 22)
Tir width=8
call cursor(3, 11)
Tir width=5
call cursor(4, 1)
Tir width=9
call cursor(5, 23)
Tir width+9
Tir width+5
Tir width+
call feedkeys("u", "x")
call cursor(6, 20)
Tir width-10
call cursor(2, 1)
Tir width-100
call cursor(1, 1)
Tir width-

call RunTest({})