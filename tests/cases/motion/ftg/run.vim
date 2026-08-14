source $TIRENVI_ROOT/tests/common.vim
lua vim.keymap.set({ 'n', 'o', 'x' }, 'tf', require('tirenvi').motion.f, { expr = true, desc = '[T]irEnvi: f pipe' })
lua vim.keymap.set({ 'n', 'o', 'x' }, 'tF', require('tirenvi').motion.F, { expr = true, desc = '[T]irEnvi: F pipe' })
lua vim.keymap.set({ 'n', 'o', 'x' }, 'tt', require('tirenvi').motion.t, { expr = true, desc = '[T]irEnvi: t pipe' })
lua vim.keymap.set({ 'n', 'o', 'x' }, 'tT', require('tirenvi').motion.T, { expr = true, desc = '[T]irEnvi: T pipe' })
lua vim.keymap.set({ 'n', 'o', 'x' }, '<Up>',   require('tirenvi').motion.block_top,    { expr = true, desc = '[T]irEnvi: block top' })
lua vim.keymap.set({ 'n', 'o', 'x' }, '<Down>', require('tirenvi').motion.block_bottom, { expr = true, desc = '[T]irEnvi: block bottom' })
lua vim.keymap.set({ 'n', 'o', 'x' }, '<Left>',   require('tirenvi').motion.cell_prev,  { expr = true, desc = '[T]irEnvi: cell previous' })
lua vim.keymap.set({ 'n', 'o', 'x' }, '<Right>', require('tirenvi').motion.cell_next,   { expr = true, desc = '[T]irEnvi: cell next' })

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial
	call At(2, 1, 3)
            lua print(Debug.layout())

CASE block#2 bottom
        execute "normal \<Down>"
            lua print(Debug.layout())

CASE block#2 top
        execute "normal \<Up>"
            lua print(Debug.layout())

CASE next cell
	call At(2, 1, 1)
        execute "normal tf"
            lua print(Debug.layout())

CASE next 2cell
        execute "normal 2tf"
            lua print(Debug.layout())

CASE prev 2cell
        execute "normal 2tF"
            lua print(Debug.layout())

CASE next cell
	call At(2, 4, 1)
        execute "normal tt"
            lua print(Debug.layout())

CASE repeat 3cell
        normal! 3;
            lua print(Debug.layout())

CASE prev cell
        execute "normal tT"
            lua print(Debug.layout())

CASE plain
	call At(1, 1, 1)
        execute "normal tT"
            lua print(Debug.layout())

call Snapshot({})

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV bottom
        execute "normal \<Down>"
        execute "normal tt"
        normal! 2;
            lua print(Debug.layout())

CASE CSV top
        execute "normal \<Up>"
            lua print(Debug.layout())

call Snapshot({ 'desc': 'motion f F t T g G' })

" ===== GFM top & bottom =====
edit $TIRENVI_ROOT/tests/data/simple.md
	call At(1, 1, 1)

CASE block#1 bottom
        execute "normal \<Down>"
            lua print(Debug.layout())

CASE block#3 bottom
        execute "normal 2\<Down>"
            lua print(Debug.layout())

CASE block#3 bottom
        execute "normal \<Down>"
            lua print(Debug.layout())

CASE block#3 top
        execute "normal \<Up>"
            lua print(Debug.layout())

CASE block#1 top
        execute "normal 2\<Up>"
            lua print(Debug.layout())

CASE block#1 top
        execute "normal \<Up>"
            lua print(Debug.layout())

CASE block#1 delete plain
        execute "normal d\<Down>"
            lua print(Debug.layout())

CASE block#1 delete NG
        execute "normal 2d\<Down>"
            lua print(Debug.layout())

call Snapshot({})

" ===== GFM cell motion =====
edit!
	call At(2, 1, 1)
    execute "normal val"
    execute "normal! d"
    execute "normal! 2dd"
    execute "normal \<Down>"
    execute "normal! dd"
	call At(2, 2, 1)
    Tir repair disable
    execute "normal! $x"

call Snapshot({})

CASE cell#1 plain
	call At(1, 1, 1)
            lua print(Debug.layout())
        execute "normal \<Right>"
        execute "normal \<Right>"
        execute "normal \<Left>"
            lua print(Debug.layout())

CASE cell#1 next
	call At(2, 2, 1)
        execute "normal \<Right>"
            lua print(Debug.layout())
        execute "normal \<Right>"
            lua print(Debug.layout())
        execute "normal \<Right>"
            lua print(Debug.layout())
        execute "normal \<Right>"
            lua print(Debug.layout())
        execute "normal \<Right>"
            lua print(Debug.layout())

CASE cell#1 prev
        execute "normal 0"
            lua print(Debug.layout())
        execute "normal \<Left>"
            lua print(Debug.layout())
        execute "normal \<Left>"
            lua print(Debug.layout())
        execute "normal \<Left>"
            lua print(Debug.layout())
        execute "normal \<Left>"
            lua print(Debug.layout())
        execute "normal \<Left>"
            lua print(Debug.layout())
        execute "normal \<Left>"
            lua print(Debug.layout())

CASE cell#1 next n
	call At(2, 1, 2)
        execute "normal 3\<Right>"
            lua print(Debug.layout())
        execute "normal 30\<Right>"
            lua print(Debug.layout())

CASE cell#1 prev n
	call At(2, 3, 2)
        execute "normal 5\<Left>"
            lua print(Debug.layout())
        execute "normal 30\<Left>"
            lua print(Debug.layout())

CASE cell#1 operator-pending
	call At(2, 2, 1)
        execute "normal 1d\<Right>"
            lua print(Debug.layout())
        execute "normal 3d\<Right>"
            lua print(Debug.layout())
	call At(2, 1, 3)
        execute "normal d\<Right>"
            lua print(Debug.layout())

call Snapshot({})

" ===== JAVA =====
CASE Java
	edit $TIRENVI_ROOT/tests/data/sample.java
        execute "normal \<Down>"
        execute "normal \<Right>"
            lua print(Debug.layout())

call Snapshot({ 'desc': 'Java' })