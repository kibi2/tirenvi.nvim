#!/bin/sh
set -eu

stylua --check $KIBI2_REPO_ROOT/lua $KIBI2_REPO_ROOT/tests > out-actual.txt