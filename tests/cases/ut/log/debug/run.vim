lua << EOF
  local root = assert(os.getenv("KIBI2_REPO_ROOT"))
  vim.opt.rtp:prepend(root)
  vim.opt.rtp:prepend(root .. "/../logger.nvim")
EOF

source $KIBI2_REPO_ROOT/tests/common.vim

edit $KIBI2_REPO_ROOT/tests/data/table2.md


lua << EOF
  log = require("tirenvi.util.log")
  local opts = {
    key = 'TIR',
    level = vim.log.levels.DEBUG,
    output = "print",
    probe = true,
  }
  log.setup(opts)
  local Context = require("tirenvi.io.context")
  local Range = require("tirenvi.util.range")
  local reader = require("tirenvi.io.reader")
	ctx =  Context.from_buf(bufnr)
  buf_parser = require("tirenvi.parser.buf_parser")
  ReadResult = require("tirenvi.io.read_result")
  Attrs = require("tirenvi.core.attrs")
  Document = require("tirenvi.core.document")
  r_result = reader.read(ctx, Range.WHOLE)
  bufdoc = buf_parser.parse(ctx, r_result, {range3 = range3} )
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

call Snapshot({})