" Destructive operations on the table display an error and perform an undo.

source $TIRENVI_ROOT/tests/common.vim

lua require("tirenvi.config").log.output = "file"
lua require("tirenvi.config").log.file_name = "/tmp/tirenvi.log"

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv
      Tir toggle
  call cursor(2, 1)
      normal! i│

call Snapshot({})