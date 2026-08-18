source $TIRENVI_ROOT/tests/common.vim

lua require("tirenvi").setup({ textobj = { cell = "h" }, })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs
	call At(1, 1, 2)
      lua print(Debug.layout())

CASE dlete column and put
    	call feedkeys("vah", "x")
    	normal! d
		sleep 1m
    	normal! $h
    	normal! p
			lua print(Debug.layout())
call Snapshot({})

CASE yank cell and put
	call At(1, 2, 3)
    	call feedkeys("vih", "x")
    	normal! y
		sleep 1m
	call At(1, 5, 3)
    	normal! p
			lua print(Debug.layout())
call Snapshot({})

CASE 2 column delete
	call At(1, 5, 1)
    	call feedkeys("v2ih", "x")
    	normal! x
		sleep 1m
			lua print(Debug.layout())
call Snapshot({})
