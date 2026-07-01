" Destructive operations on the table display an error and perform an undo.

source $TIRENVI_ROOT/tests/common.vim

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv
    call cursor(6, 0)
        normal! x

call Snapshot({})