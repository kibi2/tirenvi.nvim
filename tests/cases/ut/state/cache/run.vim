source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  local log = require("tirenvi.util.log")
  local buffer = require("tirenvi.io.buffer")
  local levels = vim.log.levels
  require("tirenvi.config").setup({
  	log = {
		level = levels.DEBUG,
		probe = true, output = "print",
  	},
  })
  Context = require("tirenvi.app.context")
  Buffer = require("tirenvi.io.buffer")
  Range = require("tirenvi.util.range")
  local lines = {}
  for irow =0, 20 do
    lines[#lines+1] = irow .. ""
  end
  ctx = Context.from_buf()
  local bufnr = ctx.bufnr
  Buffer.set_lines(ctx, Range.WHOLE, lines)

  local lines, line

  print("\nCASE buffer.get_lines(bufnr, 0, -1)")
  lines = buffer.get_lines(bufnr, 0, -1)
  log.debug(lines)
  lines = buffer.get_lines(bufnr, 0, -1)
  log.debug(lines)

  print("\nCASE buffer.get_lines(bufnr, -100, 100)")
  lines = buffer.get_lines(bufnr, -100, 100)
  log.debug(lines)

  print("\nCASE clear & buffer.get_lines(bufnr, 9, 13)")
  buffer.clear_cache()
  lines = buffer.get_lines(bufnr, 10, 13)
  log.debug(lines)

  print("\nCASE buffer.get_line(bufnr, 7)")
  line = buffer.get_line(bufnr, 7)
  log.debug(tostring(line))

  print("\nCASE buffer.get_line(bufnr, 3)")
  line = buffer.get_line(bufnr, 3)
  log.debug(tostring(line))

  print("\nCASE buffer.get_line(bufnr, 20)")
  line = buffer.get_line(bufnr, 20)
  log.debug(tostring(line))

  print("\nCASE buffer.get_line(bufnr, 11)")
  line = buffer.get_line(bufnr, 11)
  log.debug(tostring(line))

  print("\nCASE buffer.get_line(bufnr, 0)")
  line = buffer.get_line(bufnr, 0)
  log.debug(tostring(line))

  print("\nCASE buffer.get_line(bufnr, 22)")
  line = buffer.get_line(bufnr, 22)
  log.debug(tostring(line))

EOF


call Snapshot({})