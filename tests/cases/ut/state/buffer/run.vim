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
  log.probe("buffer.get_line(0, 6)")
  line = buffer.get_line(0, 6)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 2)")
  line = buffer.get_line(0, 2)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 19)")
  line = buffer.get_line(0, 19)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 10)")
  line = buffer.get_line(0, 10)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, -1)")
  line = buffer.get_line(0, -1)
  log.debug(tostring(line))
  log.probe("buffer.get_line(0, 21)")
  line = buffer.get_line(0, 21)
  log.debug(tostring(line))
EOF


call RunTest({})