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
Tir repair
echomsg b:tirenvi.attrs
sleep 1m
call Snapshot({'desc': 'after format' })
edit input.csv
sleep 1m
Tir repair disable
sleep 1m
Tir repair disable
sleep 1m
Tir repair enable
sleep 1m
Tir repair enable
sleep 1m
Tir repair of
sleep 1m
Tir repair toggle
sleep 1m
Tir repair toggle
sleep 1m
call cursor(2, 1)
execute "normal! aADD\<Esc>"
sleep 1m
Tir repair
sleep 1m
call Snapshot({'desc': 'final' })

Tir repair disable
%s /[A-z]/xx/g
execute "normal! 3G2lD"
Tir repair enable
execute "normal! 2G"
execute "normal! Onew line\<Esc>"
sleep 1m

call RunTest({})