source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  levels = vim.log.levels
  log = require("tirenvi.util.log")
  Range = require("tirenvi.util.range")
EOF

lua require("tirenvi.config").log.level = levels.DEBUG
lua require("tirenvi.config").log.single_line = true
lua require("tirenvi.config").log.output = "buffer"
lua require("tirenvi.config").log.use_timestamp = true
lua require("tirenvi.config").log.probe = false

lua log.error("error")
lua log.warn(true)
lua log.info(nil, nil)
lua log.debug(4e8)
lua log.probe(4e8)
lua log.watch("CATEGORY", "format %d %s %s", 38, "foo", Range.from_lua(12,34))

call Snapshot({})