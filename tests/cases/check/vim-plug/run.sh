#!/bin/sh
set -eu

rm -fr ~/.local/share/vimplug-test
mkdir -p ~/.local/share/vimplug-test/site/autoload

curl -fLo ~/.local/share/vimplug-test/site/autoload/plug.vim \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

pip uninstall -y tir-csv

NVIM_APPNAME=vimplug-test NVIM_TIRENVI_DEV=1 $NVIM_BIN --headless -u NONE -n \
    -c "source run.vim" \
    -c "qa!" \
    > stdout.txt 2> stderr.txt

tir-csv --version >> out-actual.txt
pip uninstall -y tir-csv 
pip install tir-csv 

LC_ALL=C sed -e '/Elapsed /d' out-actual.txt > gen.txt
mv gen.txt out-actual.txt