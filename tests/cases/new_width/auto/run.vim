source $TIRENVI_ROOT/tests/common.vim

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/table2.md

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
		call Tir("fit=")

CASE fit= grid#1 logic A // within screen width: recommended width for a 3-character column is 4
	normal! 3aO
		call Tir("fit=")

CASE fit= grid#1 logic A // within screen width: recommended width for a 4-character column is 6
	normal! 0aP
		call Tir("fit=")

CASE fit= grid#1 logic A // within screen width: recommended width for an 18-character column is 24
	normal! j018aQ
		call Tir("fit=")

CASE fit= grid#1 logic A // within screen width: recommended width for a 19-character column is 25
	normal! 0aR
		call Tir("fit=")

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/wide.csv

CASE wide CSV initial
			lua print(Debug.layout())

CASE fit= logic C // exceeds screen width
		call Tir("fit=")

CASE fit= logic B // fits within screen width
	call feedkeys("val", "x")
	normal! d
		call Tir("fit=")

call RunTest({ 'desc': 'Tir wrap' })