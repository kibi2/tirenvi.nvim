source $TIRENVI_ROOT/tests/common.vim

lua << EOF
  Buffer = require("tirenvi.io.buffer")
  Range = require("tirenvi.util.range")
  Debug = require("tirenvi.editor.debug")
  local M = require("tirenvi")
  M.setup({
	table = {
		width_mode = "nowrap",
	},
  })
EOF

edit $TIRENVI_ROOT/tests/data/simple.md

call Case("1. block#2 bottom")
lua Debug.goto(2, 1, 1)
lua require('tirenvi').motion.block_bottom()
lua print(Debug.cursor_pos())

call Case("2. block#2 top")
lua require('tirenvi').motion.block_top()
lua print(Debug.cursor_pos())

call Case("3. next cell")
execute "normal! " . luaeval("require('tirenvi.editor.motion').f()")
lua print(Debug.cursor_pos())

call Case("4. next 2cell")
execute "normal! 2" . luaeval("require('tirenvi.editor.motion').f()")
lua print(Debug.cursor_pos())

call Case("5. prev 2cell")
execute "normal! 2" . luaeval("require('tirenvi.editor.motion').F()")
lua print(Debug.cursor_pos())

call Case("6. next cell")
lua Debug.goto(2, 4, 1)
execute "normal! " . luaeval("require('tirenvi.editor.motion').t()")
lua print(Debug.cursor_pos())

call Case("7. repeat 3cell")
execute "normal! 3;"
lua print(Debug.cursor_pos())

call Case("8. prev cell")
execute "normal! " . luaeval("require('tirenvi.editor.motion').T()")
lua print(Debug.cursor_pos())

call RunTest({ 'desc': 'Tir width nowrap' })

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
vim.keymap.set({ 'n', 'o', 'x' }, 'gtf', require('tirenvi').motion.f, { expr = true, desc = '[T]irEnvi: f pipe' })
vim.keymap.set({ 'n', 'o', 'x' }, 'gtF', require('tirenvi').motion.F, { expr = true, desc = '[T]irEnvi: F pipe' })
vim.keymap.set({ 'n', 'o', 'x' }, 'gtt', require('tirenvi').motion.t, { expr = true, desc = '[T]irEnvi: t pipe' })
vim.keymap.set({ 'n', 'o', 'x' }, 'gtT', require('tirenvi').motion.T, { expr = true, desc = '[T]irEnvi: T pipe' })
vim.keymap.set('n', 'gtg', require('tirenvi').motion.block_top, { desc = '[T]irEnvi: block top' })
vim.keymap.set('n', 'gtG', require('tirenvi').motion.block_bottom, { desc = '[T]irEnvi: block bottom' })
EOF

edit $TIRENVI_ROOT/tests/data/complex.md
call cursor(2, 1)
execute "normal gtg"
execute "normal dd"
sleep 1m
execute "normal gtG"
execute "normal dd"
sleep 1m
call cursor(11, 1)
execute "normal gtg"
execute "normal dd"
sleep 1m
execute "normal gtG"
execute "normal dd"
sleep 1m
call cursor(21, 1)
execute "normal gtf"
execute "normal D"
sleep 1m

call RunTest({})