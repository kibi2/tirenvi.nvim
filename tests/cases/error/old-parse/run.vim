" When there is no parser

source $KIBI2_REPO_ROOT/tests/common.vim

lua require("tirenvi.config").parser_map.markdown.required_version = "0.2.4"
lua require("tirenvi.config").log.level = vim.log.levels.WARN
lua require("tirenvi.config").setup({})

" ===== GFM =====
edit $KIBI2_REPO_ROOT/tests/data/simple.md

call Snapshot({})