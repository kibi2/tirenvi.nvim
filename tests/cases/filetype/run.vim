source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE filetype csv -> csv
        set filetype=csv
            sleep 1m | lua print(Debug.layout())

CASE filetype csv -> markdown ->csv
        set filetype=markdown
            sleep 1m | lua print(Debug.layout())
        set filetype=csv
            sleep 1m | lua print(Debug.layout())
        Tir toggle
            sleep 1m | lua print(Debug.layout())

CASE filetype csv -> tsv
    e! $TIRENVI_ROOT/tests/data/simple.csv
        set filetype=tsv
            sleep 1m | lua print(Debug.layout())
        Tir toggle
            sleep 1m | lua print(Debug.layout())

CASE filetype markdown -> bar
    e! $TIRENVI_ROOT/tests/data/simple.md
    call At(2, 3, 1)
        normal! haADD 
            echomsg b:tirenvi.attached
            echomsg b:tirenvi.filetype
            echomsg b:tirenvi.parser.executable
        set filetype=bar
            echomsg "----"
            echomsg b:tirenvi.attached
            echomsg b:tirenvi.filetype
        normal! jdd
            echomsg "----"
            lua print(vim.b.tirenvi.attached)
            lua print(vim.b.tirenvi.filetype)
            lua print(vim.b.tirenvi.parser)

call Snapshot({})