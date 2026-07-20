source $TIRENVI_ROOT/tests/common.vim

" ===== EMBEDDED =====
CASE embedded -> //
edit $TIRENVI_ROOT/tests/data/table.txt
        Tir toggle
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'desc': 'simple md -> tir' })

CASE embedded -> ""
        Tir toggle
    normal! 7G
        Tir toggle
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'desc': 'simple md -> tir -> flat' })
