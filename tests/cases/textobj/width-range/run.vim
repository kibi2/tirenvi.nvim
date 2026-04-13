source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  textobj = {
    column = "h"
  },
})
EOF

edit $TIRENVI_ROOT/tests/data/table2.md
sleep 1m
1Tir width=8
call Snapshot({'desc': 'width = 5, 6 / 5, 3, 6' })
1,6Tir width=8
call Snapshot({'desc': 'width = 8, 8 / 5, 3, 6' })
6,8Tir width-2
call Snapshot({'desc': 'width = 6, 6 / 3, 2, 4' })
qa!

===== NG =====
call feedkeys("5G7|\<C-V>4j2l", 'x')
Tir width=9
call RunTest({'desc': 'width = 9, 9 / 3, 9, 9' })
