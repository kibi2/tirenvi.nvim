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
})
vim.g.tirenvi_initialized = false
EOF

" ----------------------------
function! SafeEdit(path)
  try
    execute 'edit ' . a:path
  catch
  endtry
endfunction

function! s:CollectMessages()
  redir => g:msgs
  silent messages
  redir END
  return split(g:msgs, "\n")
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

" ----------------------------
" opts:
"   file: 'output.csv'
function! RunTest(opts) abort
  lua vim.wait(50)

  let l:out = []

  " MESSAGE
  if !has_key(a:opts, 'nomessage')
    call add(l:out, '=== MESSAGE ===')
    let l:out += s:CollectMessages()
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

  call writefile(l:out, 'out-actual.txt')
  qa!
endfunction
