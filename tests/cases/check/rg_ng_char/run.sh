#!/bin/sh
set -eu

rg -g '*.lua' -g '*.sh' -g '*.vim' '[^\x00-\x7F]' $TIRENVI_ROOT > out-actual.txt -- no ascii
rg "\bM:[a-zA-Z_]" $TIRENVI_ROOT/lua | grep -v function >> out-actual.txt -- no colon