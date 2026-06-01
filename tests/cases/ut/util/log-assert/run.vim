source $TIRENVI_ROOT/tests/common.vim

edit input.txt

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
  log.assert(fale, "test case for log.assert ERROR", "bar")
  vim.g.tirenvi_initialized = false
  M.setup({
  	log = {
		level = levels.DEBUG,
  	},
  })
  local log = require("tirenvi.util.log")
  log.assert(fale, "test case for log.assert trace back", "bar")
EOF

call RunTest({})