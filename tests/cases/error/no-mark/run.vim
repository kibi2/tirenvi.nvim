" When file has markers

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  marks = {
    padding = "a"
  },
	log = {
		output = "buffer", -- "notify" | "buffer" | "print" | "file"
		buffer_name = "tirenvi://log",
	},
})
EOF

" ===== CSV =====
try
  edit $TIRENVI_ROOT/tests/data/simple.csv
catch
endtry

call Snapshot({})