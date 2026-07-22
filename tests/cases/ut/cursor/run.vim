source $TIRENVI_ROOT/tests/common.vim

new

lua << EOF
  Context = require("tirenvi.io.context")
  buf_lines = require("tirenvi.io.buf_lines")
  Range = require("tirenvi.util.range")
  local lines = {
    "1あA",
    "123A",
  }
  ctx = Context.from_buf()
  buf_lines.set_lines(ctx, Range.WHOLE, lines)
EOF

			lua print("irow, col_byte, col_char ")

CASE cursor pos
			lua print(Debug.layout(""))


call Snapshot({ 'desc': 'test io.cursor' })
