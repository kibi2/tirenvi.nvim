#!/bin/sh
set -eu

rg '[^\x00-\x7F]' $TIRENVI_ROOT -g '*.lua' -g '*.sh' > out-actual.txt