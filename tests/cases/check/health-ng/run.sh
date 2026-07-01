#!/bin/sh
set -eu

NVIM_TIRENVI_DEV=1 nvim --headless -u NONE -n -S run.vim > stdout.txt 2> stderr.txt

LC_ALL=C sed \
  -e 's/❌ //g' \
  -e 's/✅ //g' \
  -e 's/⚠️ //g' out-actual.txt | \
LC_ALL=C sort > gen.txt

mv gen.txt out-actual.txt
