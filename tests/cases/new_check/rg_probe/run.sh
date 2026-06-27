#!/bin/sh
set -eu

rg "log\.probe\(" $TIRENVI_ROOT/lua > out-actual.txt