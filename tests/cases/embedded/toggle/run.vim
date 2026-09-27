source $KIBI2_REPO_ROOT/tests/common.vim

" ===== EMBEDDED =====
CASE embedded -> //
edit $KIBI2_REPO_ROOT/tests/data/sample.py
        Tir toggle
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'desc': 'simple md -> tir' })

CASE embedded -> ""
        Tir toggle
    normal! 7G
        Tir toggle
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'desc': 'simple md -> tir -> flat' })
