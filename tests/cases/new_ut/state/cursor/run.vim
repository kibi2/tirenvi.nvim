source $TIRENVI_ROOT/tests/common.vim

new

lua << EOF
  Context = require("tirenvi.app.context")
  Buffer = require("tirenvi.io.buffer")
  Range = require("tirenvi.util.range")
  local lines = {
    "1234567890",
    "あいうえおかきくけこ",
    "子1丑2寅3卯4辰5巳6午7未8申9酉10戌11亥12"
  }
	ctx = Context.from_buf()
  Buffer.set_lines(ctx, Range.WHOLE, lines)
EOF

			lua print("irow, byte_col, char_col ")

CASE set (1,1) & add ABC, insert XYZ"
	lua Buffer.set_cursor_char_pos(ctx.bufnr, 1, 1)
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! aABC\<Esc>"
		lua Buffer.clear_cache()
	lua Buffer.set_cursor_char_pos(ctx.bufnr, 1, 1)
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! iXYZ\<Esc>"
		lua Buffer.clear_cache()

CASE set (2,5) & add 123, insert 789"
	lua Buffer.set_cursor_char_pos(ctx.bufnr, 2, 5)
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! a123\<Esc>"
		lua Buffer.clear_cache()
	lua Buffer.set_cursor_char_pos(ctx.bufnr, 2, 5)
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! i789\<Esc>"
		lua Buffer.clear_cache()

CASE set (3,10) & add 甲乙, insert 丙丁"
	lua Buffer.set_cursor_char_pos(ctx.bufnr, 3, 10)
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! a甲乙\<Esc>"
		lua Buffer.clear_cache()
	lua Buffer.set_cursor_char_pos(ctx.bufnr, 3, 10)
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! i丙丁\<Esc>"
		lua Buffer.clear_cache()

CASE kkjj"
      call Dump('silent ascii')
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! k"
      call Dump('silent ascii')
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! k"
      call Dump('silent ascii')
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! j"
      call Dump('silent ascii')
			lua print(Buffer.get_cursor_char_pos(ctx))
		execute "normal! j"
      call Dump('silent ascii')
			lua print(Buffer.get_cursor_char_pos(ctx))

call RunTest({ 'desc': 'test Buffer.set_cursor_char_pos' })
