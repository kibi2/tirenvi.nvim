" When there is no parser

source $KIBI2_REPO_ROOT/tests/common.vim

lua require("tirenvi.config").parser_map.csv.executable = "tir-my-csv"
lua require("tirenvi.config").log.level = vim.log.levels.WARN

" ===== CSV =====
try
  edit $KIBI2_REPO_ROOT/tests/data/simple.csv
catch
endtry

call Snapshot({})