source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE Tir toggle + undo
        Tir toggle
        Tir toggle
        u
            sleep 1m | echomsg b:tirenvi.tirbuf
        Tir toggle
        normal! 02x
            sleep 1m
        Tir toggle
        u
    normal! 1G2l
        Tir toggle
        normal! D

call Snapshot({})
