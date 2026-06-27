#!/bin/sh
set -eu

LC_ALL=C rg -g '*.lua' -g '*.sh' -g '*.vim' '[^\x00-\x7F]' $TIRENVI_ROOT > sort > out-actual.txt -- no ascii
LC_ALL=C rg "\bM:[a-zA-Z_]" $TIRENVI_ROOT/lua | grep -v function > sort >> out-actual.txt -- no colon