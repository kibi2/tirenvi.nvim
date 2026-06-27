source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  M = require("tirenvi")
  levels = vim.log.levels
  vim.g.tirenvi_initialized = false
  M.setup({
  	log = {
		level = levels.ERROR,
  	},
  })
  log = require("tirenvi.util.log")
EOF

CASE log ERROR

lua log.assert(true, "true", "bar")
lua log.assert(false, "test case for log.assert ERROR", "bar")

call Snapshot({'desc': 'ERROR' })

lua << EOF
  vim.g.tirenvi_initialized = false
  M.setup({
  	log = {
		level = levels.DEBUG,
  	},
  })
EOF

CASE log trace

lua log.assert(false, "test case for log.assert trace back", "bar")

call RunTest({ 'nomessage' })