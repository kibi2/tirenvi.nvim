source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/table2.md

lua << EOF
  local M = require("tirenvi")
  local buffer = require("tirenvi.io.buffer")
  local levels = vim.log.levels
  M.setup({
  	log = {
		level = levels.DEBUG,
		probe = true, output = "print",
  	},
  })

  local Context = require("tirenvi.app.context")
  local Request = require("tirenvi.app.request")
  local Range = require("tirenvi.util.range")
  local reader = require("tirenvi.io.reader")
	ctx =  Context.from_buf(bufnr)
  buf_parser = require("tirenvi.parser.buf_parser")
  ReadResult = require("tirenvi.app.read_result")
  Attrs = require("tirenvi.core.attrs")
  Document = require("tirenvi.core.document")
  r_result = reader.read(ctx, Range.WHOLE)
  log = require("tirenvi.util.log")
  bufdoc = buf_parser.parse(ctx, r_result, {range3 = range3} )
  first = ReadResult.lua_range(r_result)
EOF

CASE test debugger, logger
    lua log.watch("ATTR", Debug.layout("UPDATE CHACHED ATTRS:")) 
    lua Document.replace_attrs(bufdoc, r_result.range)
    lua log.watch("ATTR", Debug.layout("1DOC ATTR:"))
    lua log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
  call At(2, 1, 3)
  normal! 2j
    lua log.watch("ATTR", Debug.layout("1DOC ATTR:"))
    lua log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "UPDATE CHACHED ATTRS:")) 
    lua print(Debug.layout("", true))

call RunTest({})