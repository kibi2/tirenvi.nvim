source $TIRENVI_ROOT/tests/common.vim

call plug#begin(stdpath('data') . '/plugged')

Plug 'kibi2/tir-csv', { 'do': 'pip install .' }

call plug#end()

PlugInstall

call Snapshot({ 'desc': 'vim plug' })