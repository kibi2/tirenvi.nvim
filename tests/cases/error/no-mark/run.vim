" When file has markers

source $TIRENVI_ROOT/tests/common.vim

lua require("tirenvi.config").marks.padding = "a"
lua require("tirenvi.config").log.output = "buffer"
lua require("tirenvi.config").log.buffer_name = "tirenvi://log"

" ===== CSV =====
try
  edit $TIRENVI_ROOT/tests/data/simple.csv
catch
endtry

call Snapshot({})