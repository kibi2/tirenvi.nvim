#!/bin/sh
set -eu

LC_ALL=C rg --sort=none -g '*.lua' -g '*.sh' -g '*.vim' '[^\x00-\x7F]' $TIRENVI_ROOT > out-actual.txt -- no ascii

LC_ALL=C rg --sort=none "\bM:[a-zA-Z_]" $TIRENVI_ROOT/lua | grep -v function >> out-actual.txt -- no colon