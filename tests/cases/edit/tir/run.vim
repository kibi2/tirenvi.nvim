source $KIBI2_REPO_ROOT/tests/common.vim
lua print("test print")
echomsg "test echomsg"
let outtir = 'gen.tir'

" ===== SIMPLE MD =====
CASE simple md -> tir
edit $KIBI2_REPO_ROOT/tests/data/simple.md
        Tir _write_tir
        Tir _write_tir gen.tir
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'file': outtir, 'desc': 'simple md -> tir' })

" ===== NEW MD =====
CASE new md
edit $KIBI2_REPO_ROOT/tests/data/gen.md
        Tir _read_tir
        Tir _read_tir gen.tir
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'desc': 'simple tir -> md' })

" ===== NEW CSV =====
CASE new csv
edit $KIBI2_REPO_ROOT/tests/data/gen.csv
        Tir _read_tir gen.tir
            sleep 1m | lua print(Debug.layout())
        Tir redraw
call Snapshot({ 'desc': 'simple tir -> csv' })

" ===== NEW TXT =====
CASE new txt
edit $KIBI2_REPO_ROOT/tests/data/gen.txt
        Tir _read_tir gen.tir
            sleep 1m | lua print(Debug.layout())
call Snapshot({ 'desc': 'simple tir -> txt' })