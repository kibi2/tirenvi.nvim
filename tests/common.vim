" ===== common.vim =====

set noswapfile
set nobackup
set nowritebackup
set noundofile
set shortmess+=A

let s:root = $TIRENVI_ROOT
execute 'set rtp+=' . s:root
let g:tirenvi_test_mode = 1
filetype plugin indent on

lua << EOF
require("luacov")
local M = require("tirenvi")
M.setup({
  log = {
		level = vim.log.levels.WARN,
		-- level = vim.log.levels.DEBUG,
		use_timestamp = false,
		monitor = false,
		-- probe = false,
		probe = true,
		output = "print",
	},
  	table = {
		wrap_mode = "nowrap",
	},
})
vim.g.tirenvi_initialized = false
Debug = require("tirenvi.editor.debug")
Motion = require("tirenvi.editor.motion")
local buffer = require("tirenvi.io.buffer")
buffer.clear_cache()
buffer.set_step(3)
EOF

" ----------------------------
let g:case_no = 0
let g:case_name = ""

function! At(block, row, col) abort
  execute printf(
        \ 'lua Debug.goto(%d,%d,%d)',
        \ a:block, a:row, a:col)
endfunction

function! Tir(cmd) abort
  execute "Tir " . a:cmd
  lua print(Debug.layout())
endfunction

function! CaseImpl(id, desc) abort
  echomsg " "
  echomsg printf("--- CASE %d: %s ---", a:id, a:desc)
  let g:case_tag = printf("CASE %d", a:id)
endfunction

command! -nargs=1 CASE call CaseImpl(expand('<slnum>'), <q-args>)

function! Case(desc) abort
  let g:case_no += 1
  let g:case_name = a:desc

  echomsg " "
  echomsg printf("=== CASE%d: %s ===",
    \ g:case_no,
    \ a:desc)

endfunction

function! Dump(cmd) abort
  redir => msg
  execute a:cmd
  redir END

  let msg = substitute(msg, '\n', ' ', 'g')
  echomsg printf('%s => %s', a:cmd, msg)
endfunction

let s:last_msg_count = 0

function! s:CollectMessages() abort
  redir => l:msgs
  silent messages
  redir END
  let l:lines = split(l:msgs, "\n")
  let l:new = l:lines[s:last_msg_count :]
  let s:last_msg_count = len(l:lines)
  return l:new
endfunction

function! s:CollectDisplay()
  return getline(1, '$')
endfunction

function! s:CollectFile(path)
  if a:path !=# '' && filereadable(a:path)
    return readfile(a:path)
  endif
  return []
endfunction

function! s:CollectAll(opts) abort
  let l:out = []

  " DESCRIPTION
  if has_key(a:opts, 'desc')
    call add(l:out, '--- ' . a:opts.desc . ' ---')
  endif

  " MESSAGE
  if !has_key(a:opts, 'nomessage')
    let l:msgs = s:CollectMessages()
    call filter(l:msgs, 'v:val !~# " written$"')
    if !empty(l:msgs)
      call add(l:out, '=== MESSAGE ===')
      let l:out += l:msgs
    endif
  endif

  " DISPLAY
  call add(l:out, '')
  call add(l:out, '=== DISPLAY ===')
  let l:out += s:CollectDisplay()

  " FILE
  if has_key(a:opts, 'file')
    let l:file = s:CollectFile(a:opts.file)
    if !empty(l:file)
      call add(l:out, '')
      call add(l:out, '=== FILE ===')
      let l:out += l:file
    endif
  endif

  return l:out
endfunction

" ----------------------------
" opts:
"   file: 'output.csv'
"   desc: 'description'
function! Snapshot(opts) abort
  lua vim.wait(50)
  let l:out = s:CollectAll(a:opts)
  call writefile([''], 'out-actual.txt', 'a')
  call writefile(l:out, 'out-actual.txt', 'a')
endfunction

" ----------------------------
" opts:
"   file: 'output.csv'
"   desc: 'description'
function! RunTest(opts) abort
  lua vim.wait(50)
  let l:out = s:CollectAll(a:opts)
  call writefile(l:out, 'out-actual.txt', 'a')
  qa!
endfunction