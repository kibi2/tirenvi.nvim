source $TIRENVI_ROOT/tests/common.vim
let outcsv = 'gen.csv'
let outtsv = 'gen.tsv'
let outxxx = 'gen.xxx'

" ===== SIMPLE CSV =====
CASE simple csv
edit $TIRENVI_ROOT/tests/data/simple.csv
        write
            sleep 1m | lua print(Debug.layout())
	call At(1, 4, 2)
        Tir width=8
        execute 'write ' . outcsv
            call Snapshot({ 'file': outcsv, 'desc': 'write csv' })
        execute 'write ' . outtsv
            call Snapshot({ 'file': outtsv, 'desc': 'write tsv' })
        execute 'write ' . outxxx
            call Snapshot({ 'file': outxxx, 'desc': 'write xxx' })

" ===== COMPLEX CSV =====
CASE complex csv
edit $TIRENVI_ROOT/tests/data/complex.csv
        write
            sleep 1m | lua print(Debug.layout())
        wincmd s
        wincmd c
        bd

" ===== SIMPLE MD =====
CASE simple md
edit $TIRENVI_ROOT/tests/data/simple.md
        write
            sleep 1m | lua print(Debug.layout())

" ===== COMPLEX MD =====
CASE complex md
edit $TIRENVI_ROOT/tests/data/complex.md
        write
            sleep 1m | lua print(Debug.layout())
        Tir toggle
        bd!

call RunTest({ 'desc': 'edit save' })