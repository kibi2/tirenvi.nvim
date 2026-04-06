" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
vim.keymap.set({ 'n', 'o', 'x' }, 'gtf', require('tirenvi').motion.f, { expr = true, desc = '[T]irEnvi: f pipe' })
vim.keymap.set({ 'n', 'o', 'x' }, 'gtF', require('tirenvi').motion.F, { expr = true, desc = '[T]irEnvi: F pipe' })
vim.keymap.set({ 'n', 'o', 'x' }, 'gtt', require('tirenvi').motion.t, { expr = true, desc = '[T]irEnvi: t pipe' })
vim.keymap.set({ 'n', 'o', 'x' }, 'gtT', require('tirenvi').motion.T, { expr = true, desc = '[T]irEnvi: T pipe' })
vim.keymap.set('n', 'gtg', require('tirenvi').motion.block_top, { desc = '[T]irEnvi: block top' })
vim.keymap.set('n', 'gtG', require('tirenvi').motion.block_bottom, { desc = '[T]irEnvi: block bottom' })
EOF

edit $TIRENVI_ROOT/tests/data/complex.csv
call cursor(2, 1)
call feedkeys("gtg", "x")
call feedkeys("j", "x")
execute "normal dd"
sleep 1m
call feedkeys("gtG", "x")
call feedkeys("k", "x")
execute "normal dd"
sleep 1m

call RunTest({})