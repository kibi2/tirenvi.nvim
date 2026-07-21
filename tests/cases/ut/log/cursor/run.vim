source $TIRENVI_ROOT/tests/common.vim

new

lua << EOF
  Context = require("tirenvi.io.context")
  Buffer = require("tirenvi.io.buffer")
  Range = require("tirenvi.util.range")
  CursorNvim = require("tirenvi.cursor.nvim")
  local lines = {
    "1234567890",
    "あいうえおかきくけこ",
    "子1丑2寅3卯4辰5巳6午7未8申9酉10戌11亥12"
  }
  ctx = Context.from_buf()
  Buffer.set_lines(ctx, Range.WHOLE, lines)
	function print_cursor()
		local cursor = require("tirenvi.io.reader").cursor(ctx)
		print(cursor.row_cur, cursor.col_byte, cursor.col_char)
	end
EOF

			lua print("irow, col_byte, col_char ")

CASE set (1,1) & add ABC, insert XYZ"
	lua CursorNvim.restore_disp(ctx, 1, 1)
			lua print_cursor(ctx)
		normal! aABC
		lua Buffer.clear_cache()
	lua CursorNvim.restore_disp(ctx, 1, 1)
			lua print_cursor(ctx)
		normal! iXYZ
		lua Buffer.clear_cache()

CASE set (2,5) & add 123, insert 789"
	lua CursorNvim.restore_disp(ctx, 2, 9)
			lua print_cursor(ctx)
		normal! a123
		lua Buffer.clear_cache()
	lua CursorNvim.restore_disp(ctx, 2, 9)
			lua print_cursor(ctx)
		normal! i789
		lua Buffer.clear_cache()

CASE set (3,10) & add 甲乙, insert 丙丁"
	lua CursorNvim.restore_disp(ctx, 3, 15)
			lua print_cursor(ctx)
		normal! a甲乙
		lua Buffer.clear_cache()
	lua CursorNvim.restore_disp(ctx, 3, 15)
			lua print_cursor(ctx)
		normal! i丙丁
		lua Buffer.clear_cache()

CASE kkjj"
      		call Dump('silent ascii')
			lua print_cursor(ctx)
		normal! k
      		call Dump('silent ascii')
			lua print_cursor(ctx)
		normal! k
      		call Dump('silent ascii')
			lua print_cursor(ctx)
		normal! j
      		call Dump('silent ascii')
			lua print_cursor(ctx)
		normal! j
      		call Dump('silent ascii')
			lua print_cursor(ctx)

call Snapshot({ 'desc': 'test CursorNvim.restore_disp' })
