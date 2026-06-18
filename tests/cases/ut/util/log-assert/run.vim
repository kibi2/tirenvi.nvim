source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  local M = require("tirenvi")
  local log = require("tirenvi.util.log")
  local levels = vim.log.levels
  vim.g.tirenvi_initialized = false
  M.setup({
  	log = {
		level = levels.ERROR,
  	},
  })
  log.assert(true, "true", "bar")
  log.assert(false, "test case for log.assert ERROR", "bar")
EOF

call Snapshot({'desc': 'ERROR' })

lua << EOF
  vim.g.tirenvi_initialized = false
  M.setup({
  	log = {
		level = levels.DEBUG,
  	},
  })
  local log = require("tirenvi.util.log")
  log.assert(false, "test case for log.assert trace back", "bar")
EOF

call RunTest({ "nomessage": 'true' })