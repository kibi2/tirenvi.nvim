source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
echomsg "init" b:tirenvi.prev_width_mode b:tirenvi.width_mode
echomsg b:tirenvi.attrs[1]
sleep 1m
Tir width fix
echomsg "-> fix" b:tirenvi.prev_width_mode b:tirenvi.width_mode
echomsg b:tirenvi.attrs[1]
sleep 1m
execute "normal! 3G"
Tir width auto
echomsg "-> auto" b:tirenvi.prev_width_mode b:tirenvi.width_mode
echomsg b:tirenvi.attrs[1]
sleep 1m
Tir width=10
echomsg "widt=10" b:tirenvi.prev_width_mode b:tirenvi.width_mode
echomsg b:tirenvi.attrs[1]
sleep 1m
Tir width auto
execute "normal! 6G050aG\<Esc>"
sleep 1m
echomsg "row:col=2:3" b:tirenvi.prev_width_mode b:tirenvi.width_mode
echomsg b:tirenvi.attrs[1]
execute "normal! 6G050aG\<Esc>"
sleep 1m
echomsg "row:col=2:3" b:tirenvi.prev_width_mode b:tirenvi.width_mode
echomsg b:tirenvi.attrs[1]

call RunTest({})