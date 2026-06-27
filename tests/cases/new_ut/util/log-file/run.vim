source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  local M = require("tirenvi")
  local levels = vim.log.levels
  M.setup({
  	log = {
		level = levels.DEBUG,
		single_line = false,
		output = "file",
		file_name = "./gen.tirenvi",
		use_timestamp = false,
		probe = true,
  	},
  })
  Range = require("tirenvi.util.range")
  log = require("tirenvi.util.log")
EOF

edit $TIRENVI_ROOT/tests/data/empty.txt

lua log.error("error")
lua log.warn(3.14)
lua log.info(nil)
lua log.debug(false)
lua log.probe(-3e-3)
lua log.watch("CATEGORY", "format %d %s %s", 38, "foo", Range.short(Range.from_lua(12,34)))

call RunTest({})