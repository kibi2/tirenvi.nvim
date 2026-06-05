" Verify the screen display after executing the Tir toggle command.
" Display in flat file format.

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
parser_map = {
		csv = { executable = "tir-csv", required_version = "0.1.4" },
		tsv = { executable = "tir-csv", options = { "--delimiter", "\t" }, required_version = "0.1.1" },
		markdown = { executable = "tir-gfm-lite", allow_plain = true, required_version = "0.1" },
		pukiwiki = { executable = "tir-pukiwiki", allow_plain = foo },
},
})
EOF

edit $TIRENVI_ROOT/tests/data/simple.csv
checkhealth tirenvi

call RunTest({ "nomessage": 'true' })