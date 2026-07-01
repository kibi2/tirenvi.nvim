source $TIRENVI_ROOT/tests/common.vim

" ===== CSV file command =====
let outfoo = 'gen.foo'

edit $TIRENVI_ROOT/tests/data/simple.csv
	call At(1, 1, 1)
        normal! x
        execute 'file ' . outfoo
        write

call Snapshot({ 'desc': 'file ' . outfoo, 'file': outfoo })

" ===== CSV write command =====
let outcsv = 'gen.csv'
let outtsv = 'gen.tsv'

edit $TIRENVI_ROOT/tests/data/simple.csv
	call At(1, 2, 1)
        normal! D
        sleep 1m
        execute 'write ' . outcsv

call Snapshot({ 'desc': 'file ' . outcsv, 'file': outcsv })

        execute 'write ' . outtsv

call Snapshot({ 'desc': 'file ' . outtsv, 'file': outtsv })
