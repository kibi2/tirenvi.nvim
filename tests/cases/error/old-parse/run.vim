" When there is no parser

source $TIRENVI_ROOT/tests/common.vim

lua require("tirenvi.config").parser_map.markdown.required_version = "0.2.4"
lua require("tirenvi.config").log.level = vim.log.levels.WARN
lua require("tirenvi.config").setup({})

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

call Snapshot({})