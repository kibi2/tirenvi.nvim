#!/bin/sh
set -eu

rg -g '*.lua' -g '*.sh' -g '*.vim' '[^\x00-\x7F]' $TIRENVI_ROOT > out-actual.txt