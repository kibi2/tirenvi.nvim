source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md

lua << EOF
  local opts = {
  	log = {
		level = vim.log.levels.DEBUG,
		single_line = false,
		output = "file",
		file_name = "./out-actual.txt",
		use_timestamp = false,
		probe = true,
  	},
  }
  require("tirenvi").setup(opts)
  Range = require("tirenvi.util.range")
  log = require("tirenvi.util.log")
  Context = require("tirenvi.app.context")
EOF

CASE log.xxx(...)
		lua log.error("error")
		lua log.warn(3.14)
		lua log.info(nil)
		lua log.debug(false)
		lua log.probe(-3e-3)
		lua log.watch("CATEGORY", "format %d %s %s", 38, "foo", Range.short(Range.from_lua(12,34)))

CASE move cursor
		lua ctx = Context.from_buf()
		lua Debug.show_attr_marks(ctx)
	
call Snapshot({ 'desc': 'log file' })