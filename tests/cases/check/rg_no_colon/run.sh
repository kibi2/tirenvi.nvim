#!/bin/sh
set -eu

rg "\bM:[a-zA-Z_]" $TIRENVI_ROOT/lua | grep -v function > out-actual.txt