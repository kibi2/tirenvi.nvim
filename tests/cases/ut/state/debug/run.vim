source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/table2.md

lua << EOF
  local M = require("tirenvi")
  local log = require("tirenvi.util.log")
  local buffer = require("tirenvi.io.buffer")
  local levels = vim.log.levels
  M.setup({
  	log = {
		level = levels.DEBUG,
		probe = true, output = "print",
  	},
  })

  local Context = require("tirenvi.app.context")
  local Attrs = require("tirenvi.core.attrs")
  local Request = require("tirenvi.app.request")
  local Range = require("tirenvi.util.range")
  local req_r = Request.new_reader(Range.WHOLE)
  local reader = require("tirenvi.io.reader")
  local buf_parser = require("tirenvi.parser.buf_parser")
  local Document = require("tirenvi.core.document")
	local ctx =  Context.from_buf(bufnr)
  reader.read(ctx, req_r)
  log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "UPDATE CHACHED ATTRS:")) 
  local buf_doc = buf_parser.parse_text_driven(ctx, req_r, range3)
  local first = Request.lua_range(req_r)
  Document.set_attr_range(buf_doc, first)
  log.watch("ATTR", Document.debug_attrs(buf_doc, "1DOC ATTR:"))
EOF


call RunTest({})