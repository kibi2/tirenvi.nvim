#!/bin/sh
set -eu

NVIM_TIRENVI_DEV=1 nvim --headless -u NONE -n -S run.vim > stdout.txt 2> stderr.txt

LC_ALL=C sed -E 's/:[0-9]+]//g' out-actual.txt > gen.txt
mv gen.txt out-actual.txt
