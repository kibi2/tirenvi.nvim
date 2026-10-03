source $KIBI2_REPO_ROOT/tests/common.vim

" ===== WRITE_PRE/POST =====
edit $KIBI2_REPO_ROOT/tests/data/wide.csv

CASE restore curser : write case : restore_mode = buffer
	    Tir fit=2
	    normal! 43G
	    normal! 20|
	    w! gen.csv
	    lua print(Debug.layout())

call Snapshot({ 'desc': 'restore cursor' })