#!/bin/sh
# Open a CSV file, save it immediately, and verify the file contents.
# This also serves as a check for idempotency.
set -eu

# Prepare the input data
cp $TIRENVI_ROOT/tests/data/complex.csv ./gen.csv
# Load gen.csv, make no changes, and save it as is
NVIM_TIRENVI_DEV=1 nvim --headless -u NONE -n -S read-and-save.vim > stdout.txt 2> stderr.txt
