#!/bin/sh
set -eu

LC_ALL=C sed \
  -e 's/❌ //g' \
  -e 's/✅ //g' \
  -e 's/⚠️ //g' \
  -e '/^tirenvi:/d' \
  out-actual.txt > gen.txt

mv gen.txt out-actual.txt
