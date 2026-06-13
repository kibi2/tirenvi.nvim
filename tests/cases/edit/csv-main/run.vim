source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/complex.csv

call Snapshot({})

bd
qa!