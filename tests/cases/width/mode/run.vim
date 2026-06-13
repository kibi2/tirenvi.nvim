source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.md
echomsg "init" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width fix
echomsg "-> fix" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width max
echomsg "-> max" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width fit 3
echomsg "-> fit 3" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width fix 5
echomsg "-> fix 5" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width toggle
echomsg "toggle" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width toggle
echomsg "toggle" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width toggle
echomsg "toggle" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width toggle
echomsg "toggle" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width fit 99
echomsg "-> fit 99" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width=
echomsg "-> set" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
execute "normal! 3G"
Tir width=
echomsg "-> set" b:tirenvi.prev_width_mode b:tirenvi.width_mode
sleep 1m
Tir width auto
echomsg "-> auto" b:tirenvi.prev_width_mode b:tirenvi.width_mode

call RunTest({})