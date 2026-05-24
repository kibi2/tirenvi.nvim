" Verify the screen display after executing the Tir toggle command.
" Display in flat file format.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
Tir repair toggle
sleep 1m
execute "normal! 3G"
execute "normal! 3D"
sleep 1m
%s /o/QW/g
sleep 1m
execute "normal! 3G"
execute "normal! 3yy"
execute "normal! 6G"
execute "normal! p"
echomsg b:tirenvi.attrs
sleep 1m
call Snapshot({'desc': 'before format' })
Tir redraw
echomsg b:tirenvi.attrs
sleep 1m

call RunTest({})