" When there is no parser

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  parser_map = {
		markdown = { executable = "tir-gfm-lite", allow_plain = true, required_version = "0.2.4" },
  },
  log = { level = vim.log.levels.WARN }
})
EOF

try
  edit $TIRENVI_ROOT/tests/data/simple.md
catch
endtry

" call SafeEdit($TIRENVI_ROOT . '/tests/data/complex.csv')
call RunTest({})