" Verify the screen display state immediately after opening the CSV file
" The CSV file contains line breaks and tabs
" - It is formatted as a table with aligned borders
" - Special characters are embedded to align the borders
" - Line breaks and tabs are replaced with special characters, and one record is displayed per line

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/complex.csv

call Snapshot({})

bd
qa!