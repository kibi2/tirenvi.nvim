#!/bin/sh
set -eu

rg "log\.probe\(" $KIBI2_REPO_ROOT/lua > out-actual.txt