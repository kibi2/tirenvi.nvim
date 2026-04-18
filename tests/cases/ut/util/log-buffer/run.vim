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
		single_line = true,
		output = "buffer",
		use_timestamp = true,
		probe = false,
  	},
  })
  log.error("error")
  log.warn(true)
  log.info(nil, nil)
  log.debug(4e8)
  log.probe(4e8)
  log.watch("CATEGORY", "format %d %s %s", 38, "foo", Range.new(12,34))
EOF

call RunTest({})