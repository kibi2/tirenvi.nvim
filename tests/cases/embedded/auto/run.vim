source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md
    set ft=bar
    4,10s/^/ # #  /g
	Tir toggle

CASE initial cached attrs
			lua print(Debug.layout())

CASE fit= plain#1
	call At(1, 1, 1)
		call Tir("fit=")

CASE fit= grid#1
	call At(1, 2, 1)
		call Tir("fit=")

CASE fit= grid#1 logic A // within screen width: recommended width for an empty column is 3
	call feedkeys("vil", "x")
		normal! d
			sleep 1m | lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for a 3-character column is 4
		normal! 3aO
			sleep 1m | lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for a 4-character column is 6
		normal! 0aP
			sleep 1m | lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for an 18-character column is 24
		normal! j018aQ
			sleep 1m | lua print(Debug.layout())

CASE fit= grid#1 logic A // within screen width: recommended width for a 19-character column is 25
		normal! 0aR
			sleep 1m | lua print(Debug.layout())

CASE fit= grid#1 // max or fit
		e!
	call At(2, 4, 1)
		Tir wrap
		normal! 060aG
			sleep 1m | lua print(Debug.layout())
			
call Snapshot({ 'desc': 'GFM' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/wide.csv
    set ft=bar
    %s/^/ # /g

CASE wide CSV initial
			lua print(Debug.layout())

CASE fit= logic C // exceeds screen width
		call Tir("fit=")

CASE fit= logic B // fits within screen width
	call feedkeys("val", "x")
	normal! d
		call Tir("fit=")

call Snapshot({ 'desc': 'Tir wrap' })