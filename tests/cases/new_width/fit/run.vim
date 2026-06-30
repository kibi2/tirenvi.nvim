source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

CASE initial cached attrs
            lua print(Debug.layout())

CASE fit+2 plain#1
	call At(1, 1, 1)
	    call Tir("fit+2")

CASE fit-4 grid#1
	call At(2, 1, 1)
	    call Tir("fit-4")

CASE fit - 10 grid#1
	call At(2, 1, 1)
	    call Tir("fit - 10")

CASE fit+10 grid#1
	call At(2, 4, 2)
	    call Tir("fit+10")

CASE fit=80 grid#2
	call At(4, 2, 3)
	    call Tir("fit=80")

CASE fit=1 grid#2
	call At(4, 3, 2)
	    call Tir("fit=2")

CASE fit-10 plain#2
	call At(3, 1, 2)
	    call Tir("fit-10")

CASE fit - 10 gird#2
	call At(4, 3, 2)
	    call Tir("fit - 10")

CASE fit =200 grid#2
	call At(2, 3, 2)
	    call Tir("fit =200")

CASE fit!3
	call At(3, 2, 3)
	    call Tir("fit!3")

CASE fit foo
	call At(1, 2, 3)
	    call Tir("fit foo")

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE CSV fit =100
	    call Tir("fit =100")

CASE CSV fit+50
	    call Tir("fit+50")

CASE CSV fit-100
	    call Tir("fit-100")

call RunTest({ 'desc': 'Tir fit' })