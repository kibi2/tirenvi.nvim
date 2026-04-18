source $TIRENVI_ROOT/tests/common.vim

edit input.txt

lua << EOF
  local M = require("tirenvi")
  local log = require("tirenvi.util.log")
  local Range = require("tirenvi.util.range")
  local levels = vim.log.levels
  M.setup({
  	log = {
		level = levels.DEBUG,
		single_line = false,
		output = "file",
		file_name = "./tirenvi.gen",
		use_timestamp = false,
		probe = true,
  	},
  })
  log.error("error")
  log.warn(3.14)
  log.info(nil)
  log.debug(false)
  log.probe(-3e-3)
  log.watch("CATEGORY", "format %d %s %s", 38, "foo", Range.new(12,34))
EOF

call RunTest({})