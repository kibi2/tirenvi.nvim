source $TIRENVI_ROOT/tests/common.vim

lua << EOF
function print_wrap(title)
    local Context = require("tirenvi.app.context")
	ctx =  Context.from_buf()
    require("tirenvi.init").auto_wrap(ctx)
    print(tostring(vim.wo[0].wrap) .. " : " .. (title or ""))
end
EOF

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial
	call At(1, 2, 1)
    normal! 100aP
	call At(2, 2, 1)
    normal! 100aG
            lua vim.wo[0].wrap = false
            lua print(vim.wo[0].wrap)

CASE GFM plain, grid
	call At(1, 1, 1) | lua print_wrap("plain-short")
	call At(2, 1, 1) | lua print_wrap("grid-short")
	call At(1, 2, 1) | lua print_wrap("plain")
	call At(1, 1, 1) | lua print_wrap("plain-short")
	call At(2, 1, 1) | lua print_wrap("grid-short")
	call At(2, 2, 1) | lua print_wrap("grid")
	call At(1, 1, 1) | lua print_wrap("plain-short")
	call At(2, 1, 1) | lua print_wrap("grid-short")

" ===== CSV =====
edit! $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV grid
	call At(1, 2, 1)
    normal! h100aC
            lua vim.wo[0].wrap = true
            lua print(vim.wo[0].wrap)

	call At(1, 1, 1) | lua print_wrap("gird-short")
	call At(1, 3, 1) | lua print_wrap("gird-short")
	call At(1, 2, 1) | lua print_wrap("grid")
	call At(1, 1, 1) | lua print_wrap("gird-short")
	call At(1, 2, 1) | lua print_wrap("grid")
            
" ===== CONFIG =====
lua require("tirenvi.config").ui.manage_wrap = false

CASE CSV confg
    lua vim.wo[0].wrap = true
	call At(1, 3, 1) | lua print_wrap("gird-short")
	call At(1, 2, 1) | lua print_wrap("grid")
    lua vim.wo[0].wrap = false
	call At(1, 3, 1) | lua print_wrap("gird-short")
	call At(1, 2, 1) | lua print_wrap("grid")

call Snapshot({ 'desc': 'manage wrap' })
