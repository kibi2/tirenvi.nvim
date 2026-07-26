source $TIRENVI_ROOT/tests/common.vim

lua require("tirenvi.config").parser_map.csv.required_version = "0.1.4"
lua require("tirenvi.config").parser_map.tsv.required_version = "0.1.1"
lua require("tirenvi.config").parser_map.markdown.required_version = "0.1"
lua require("tirenvi.config").parser_map.pukiwiki.allow_plain = foo
lua require("tirenvi.config").setup({})

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv
		checkhealth tirenvi

call Snapshot({ 'nomessage': 'true', 'desc': 'checkhealth ok case' })

lua require("tirenvi.config").parser_map.csv.required_version = "1.1.4"
lua require("tirenvi.config").parser_map.tsv.required_version = "0.2.4"
lua require("tirenvi.config").parser_map.markdown.required_version = "0.2"
lua require("tirenvi.config").parser_map.pukiwiki.required_version = "0."
lua require("tirenvi.config").parser_map.foo = { executable = "foo", required_version = "0.1.1" }
lua require("tirenvi.config").setup({})


" ===== TXT =====
edit $TIRENVI_ROOT/tests/data/empty.txt
        checkhealth tirenvi

call Snapshot({ 'nomessage': 'true', 'desc': 'checkhealth ok case' })
" call Snapshot({ 'desc': 'checkhealth ok case' })