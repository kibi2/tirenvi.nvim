source $TIRENVI_ROOT/tests/common.vim

lua require("tirenvi.config").log.level = vim.log.levels.ERROR
lua require("tirenvi.config").setup({})
lua log = require("tirenvi.util.log")

CASE log ERROR

lua log.assert(true, "true", "bar")
lua log.assert(false, "test case for log.assert ERROR", "bar")

call Snapshot({'desc': 'ERROR' })

lua require("tirenvi.config").log.level = vim.log.levels.DEBUG
lua require("tirenvi.config").setup({})

CASE log trace

lua log.assert(false, "test case for log.assert trace back", "bar")

call Snapshot({ 'nomessage' })