source $TIRENVI_ROOT/tests/common.vim

lua << EOF
function print_key(key)
  local line = {"[CI] key = "}
  for i = 1, #key do
    table.insert(line, string.format("%02X", string.byte(key, i)))
  end
  print(table.concat(line))
end
function insert_tab()
  local key = require("tirenvi.editor.commands").keymap_tab(0)
  vim.api.nvim_put({key}, "c", true, true)
  print_key(key)
end
EOF

" ===== GFM =====
edit $TIRENVI_ROOT/tests/data/simple.md

CASE initial cached attrs
      lua print(Debug.layout())

CASE <expand tab>Alice
set expandtab
	call At(2, 3, 1)
    execute "normal! a\<Tab>\<Esc>"
      sleep 1m | lua print(Debug.layout())

CASE <expand tab> plain
    set expandtab
  call At(1, 2, 1)
    execute "normal! a\<Tab>\<Esc>"
    sleep 1m | lua print(Debug.layout())

CASE <noexpand tab> plain
    set noexpandtab
  normal! 02G10l
    lua insert_tab()
    sleep 1m | lua print(Debug.layout())

CASE <noexpand tab> Bob Age
set noexpandtab
	call At(2, 4, 2) | normal! l
    lua insert_tab()
      sleep 1m | lua print(Debug.layout())

call Snapshot({ 'desc': 'GFM' })

" ===== CSV =====
edit $TIRENVI_ROOT/tests/data/simple.csv

CASE initial cached attrs
      lua print(Debug.layout())

CASE <expand tab>Alice
set noexpandtab
	call At(1, 2, 1)
    lua insert_tab()
      sleep 1m | lua print(Debug.layout())

call Snapshot({ 'desc': 'CSV' })

" ===== FLAT =====

CASE <noexpand tab>FLAT
    e!
    set noexpandtab
    Tir toggle
  call cursor(1, 1)
      lua insert_tab()

call Snapshot({ 'desc': 'FLAT' })