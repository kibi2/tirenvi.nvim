#!/bin/sh
# Open a CSV file, save it immediately, and verify the file contents.
# This also serves as a check for idempotency.
set -eu

NVIM_TIRENVI_DEV=1 nvim --headless -u NONE -n -S run.vim > stdout.txt 2> stderr.txt

sort out-actual.txt > gen.txt
mv gen.txt out-actual.txt
