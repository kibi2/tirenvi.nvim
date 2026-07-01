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
        normal! aADD 
        set filetype=bar
            echomsg b:tirenvi.attached
        normal! jdd
            lua print(vim.b.tirenvi.attached)

call RunTest({})