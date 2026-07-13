#!/bin/sh
set -eu

NVIM_TIRENVI_DEV=1 $NVIM_BIN --headless -u NONE -n \
  -c "source run.vim" \
  -c "qa!" \
  > stdout.txt 2> stderr.txt

LC_ALL=C sed \
  -e 's/❌ //g' \
  -e 's/✅ //g' \
  -e 's/⚠️ //g' \
  -e '/^tirenvi:/d' \
  out-actual.txt > gen.txt

mv gen.txt out-actual.txt
