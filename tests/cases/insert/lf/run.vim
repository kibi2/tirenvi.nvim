source $TIRENVI_ROOT/tests/common.vim

lua << EOF
log = require("tirenvi.util.log")
function print_key(key)
  local line = {"[CI] key = "}
  for i = 1, #key do
    table.insert(line, string.format("%02X", string.byte(key, i)))
  end
  print(table.concat(line))
end
function print_lf()
  local key = require("tirenvi.editor.commands").keymap_lf(0)
  print_key(key)
end
EOF

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE lf-at-start <lf>|2-1|2-2|2-3|
    normal! 2G0
      lua print_lf()

CASE lf-in-cell |<lf char>2-1|2-2|2-3|
    normal! 3G0l
      lua print_lf()

CASE lf-in-flat
    e!
    Tir toggle
  normal! 2G0
      lua print_lf()
  normal! 3G0l
      lua print_lf()

call Snapshot({'desc': 'The LF encoding changes depending on the location'})