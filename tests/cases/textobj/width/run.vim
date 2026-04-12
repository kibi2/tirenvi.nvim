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
"                              5, 3, 11
execute "normal! 1j11l"
Tir width=8
sleep 1m
"                              5, 3, 8
execute "normal! 0gg2j6l"
Tir width=5
sleep 1m
"                              5, 5, 8
execute "normal! 0gg4j5l"
Tir width=9
sleep 1m
"                              9, 5, 8
execute "normal! 0gg3j9l"
Tir width+9
sleep 1m
"                              18, 5, 8
Tir width+5
sleep 1m
"                              23, 5, 8
Tir width+
sleep 1m
"                              24, 5, 8
call feedkeys("u", "x")
sleep 1m
"                              23, 5, 8
execute "normal! 0gg6j6l"
Tir width-10
sleep 1m
"                              13, 5, 8
execute "normal! 0gg8j1l"
Tir width=10
sleep 1m
"                              13, 5, 8
execute "normal! 0gg3j$"
Tir width=20
sleep 1m
"                              13, 5, 8
call cursor(2, 1)
Tir width-100
sleep 1m
"                              2, 5, 8
call cursor(1, 1)
Tir width-
sleep 1m
"                              2, 5, 8
execute "normal! 0gg3j3l"
Tir width=
sleep 1m
"                              2, 3, 8

call RunTest({})
