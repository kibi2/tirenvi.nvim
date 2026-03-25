#!/bin/sh
set -eu

rg -n -g '*.lua' -g '*.sh' '[^\x00-\x7F]' $TIRENVI_ROOT > out-actual.txt