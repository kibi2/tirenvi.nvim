#!/bin/sh
set -eu

stylua --check $TIRENVI_ROOT/lua $TIRENVI_ROOT/tests > out-actual.txt