source $TIRENVI_ROOT/tests/common.vim

edit input.txt

lua << EOF
  local M = require("tirenvi")
  local log = require("tirenvi.util.log")
  local buffer = require("tirenvi.io.buffer")
  local levels = vim.log.levels
  M.setup({
  	log = {
		level = levels.DEBUG,
		probe = true, output = "print",
  	},
  })


  local lines, line
  log.probe("buffer.get_lines(0, 0, -1)")
  lines = buffer.get_lines(0, 0, -1)
  log.debug(lines)
  lines = buffer.get_lines(0, 0, -1)
  log.debug(lines)
  log.probe("buffer.get_lines(0, -100, 100)")
  lines = buffer.get_lines(0, -100, 100)
  log.debug(lines)
  log.probe("clear & buffer.get_lines(0, 9, 13)")
  buffer.clear_cache()
  lines = buffer.get_lines(0, 9, 13)
  log.debug(lines)
  log.probe("buffer.get_line(0, 7)")
  line = buffer.get_line(0, 7)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 3)")
  line = buffer.get_line(0, 3)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 20)")
  line = buffer.get_line(0, 20)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 11)")
  line = buffer.get_line(0, 11)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 0)")
  line = buffer.get_line(0, 0)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 22)")
  line = buffer.get_line(0, 22)
  log.debug(tostring(line))
EOF


call RunTest({})