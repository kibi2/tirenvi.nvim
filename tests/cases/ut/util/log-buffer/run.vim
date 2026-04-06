source $TIRENVI_ROOT/tests/common.vim

edit input.txt

lua << EOF
  local M = require("tirenvi")
  local log = require("tirenvi.util.log")
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
EOF

call RunTest({})