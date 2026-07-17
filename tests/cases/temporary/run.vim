source $TIRENVI_ROOT/tests/common.vim
let outtir = 'gen.tir'

" ===== EMBEDDED =====
CASE embedded -> tir
edit $TIRENVI_ROOT/tests/data/table.txt
        Tir toggle
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'file': outtir, 'desc': 'simple md -> tir' })
