" Verify the screen display after executing the Tir toggle command.
" Display in flat file format.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width fix
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width max
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width fit 3
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width fix 5
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width toggle
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width toggle
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width toggle
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width toggle
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width fit 99
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
Tir width=
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages
sleep 1m
execute "normal! 3G"
Tir width=
echomsg b:tirenvi.width_mode
echomsg b:tirenvi.width_fit_pages

call RunTest({})