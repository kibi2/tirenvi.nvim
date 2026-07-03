source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md

lua << EOF
  local M = require("tirenvi")
  local levels = vim.log.levels
  M.setup({
  	log = {
		level = levels.DEBUG,
		single_line = false,
		output = "file",
		-- file_name = "./gen.tirenvi",
		file_name = "./out-actual.txt",
		use_timestamp = false,
		probe = true,
  	},
  })
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