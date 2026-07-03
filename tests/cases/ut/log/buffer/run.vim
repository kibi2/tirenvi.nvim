source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  local M = require("tirenvi")
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
  log = require("tirenvi.util.log")
  Range = require("tirenvi.util.range")
EOF

lua log.error("error")
lua log.warn(true)
lua log.info(nil, nil)
lua log.debug(4e8)
lua log.probe(4e8)
lua log.watch("CATEGORY", "format %d %s %s", 38, "foo", Range.from_lua(12,34))

call Snapshot({})