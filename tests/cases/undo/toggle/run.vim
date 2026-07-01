source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE Tir toggle + undo
        Tir toggle
        Tir toggle
        u
            sleep 1m | echomsg b:tirenvi.flat
    normal! 1G2l
        normal! D

call Snapshot({})
