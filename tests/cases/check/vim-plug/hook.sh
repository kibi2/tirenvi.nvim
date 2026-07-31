#!/bin/sh

# test for neovim plugin manager "vim-plug"

set -eu

case "$1" in
pre)
    rm -fr ~/.local/share/vimplug-test
    mkdir -p ~/.local/share/vimplug-test/site/autoload
    curl -fLo ~/.local/share/vimplug-test/site/autoload/plug.vim \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    pip uninstall -y tir-csv
    ;;
post)
    tir-csv --version >> out-actual.txt
    pip uninstall -y tir-csv 
    pip install tir-csv 
    LC_ALL=C sed -e '/Elapsed /d' out-actual.txt > gen.txt
    mv gen.txt out-actual.txt
    ;;
esac