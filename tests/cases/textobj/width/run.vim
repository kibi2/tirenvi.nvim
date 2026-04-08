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
sleep 1m
call cursor(2, 22)
Tir width=8
sleep 1m
call cursor(3, 11)
Tir width=5
sleep 1m
call cursor(4, 1)
Tir width=9
sleep 1m
call cursor(5, 23)
Tir width+9
sleep 1m
Tir width+5
sleep 1m
Tir width+
sleep 1m
call feedkeys("u", "x")
sleep 1m
call cursor(6, 20)
Tir width-10
sleep 1m
call cursor(2, 1)
Tir width-100
sleep 1m
call cursor(1, 1)
Tir width-
sleep 1m

call RunTest({})