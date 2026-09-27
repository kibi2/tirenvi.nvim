" Destructive operations on the table display an error and perform an undo.

source $KIBI2_REPO_ROOT/tests/common.vim

" ===== CSV =====
edit $KIBI2_REPO_ROOT/tests/data/simple.csv
    call cursor(6, 0)
        normal! x

call Snapshot({})