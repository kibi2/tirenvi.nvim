#!/bin/sh
set -eu

case "${1:-run}" in
  pre)
    ;;
  post)
    LC_ALL=C sed \
      -e 's/❌ //g' \
      -e 's/✅ //g' \
      -e 's/⚠️ //g' \
      -e '/^tirenvi:/d' \
      -e '/^$/d' \
      -e '/^--- checkhealth ok case ---$/d' \
      out-actual.txt > gen.txt
    mv gen.txt out-actual.txt
    ;;
esac
