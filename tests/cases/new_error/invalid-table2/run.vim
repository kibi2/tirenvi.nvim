" Destructive operations on the table display an error and perform an undo.

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  log = {
    output = "file", -- "notify" | "buffer" | "print" | "file"
    file_name = "/tmp/tirenvi.log",
  },
})
EOF

edit $TIRENVI_ROOT/tests/data/simple.csv
Tir toggle
call cursor(2, 1)
execute "normal! i│\<Esc>"

call RunTest({})