" When there is no parser

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  parser_map = {
    csv = { executable = "tir-my-csv" },
  },
  log = { level = vim.log.levels.WARN }
})
EOF

" ===== CSV =====
try
  edit $TIRENVI_ROOT/tests/data/simple.csv
catch
endtry

call RunTest({})