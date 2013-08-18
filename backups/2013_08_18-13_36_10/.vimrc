set autoindent           " Preserve current indent on new lines
set backspace=indent,eol,start    "Make backspaces delete sensibly
set backup               " keep backups of files when overwriting them
set backupdir=~/.vim/tmp " keep backups in this directory
set directory=~/.vim/tmp " put swap files in this directory
set expandtab            " Convert all tabs typed to spaces
set iskeyword+=:         " :: in Perl
set matchpairs+=<:>      " Allow % to bounce between angles too
set modeline             " look for modelines in the first 10 lines
set modelines=10         " ibid
"set number               " print line number in front of each line
set ruler                " Display cursor line number and column in the status bar
set shiftround           " Indent/outdent to nearest tabstop
set shiftwidth=2         " Indent/outdent by two columns
set showmatch            " Highlight matching braces
set smartindent          " Indent smartly
set smarttab             " do the right thing with tabs
set softtabstop=2        " Number of spaces that a tab counts for
set t_Co=256             " Use 256 colors
set tabstop=8            " Tabs use eight columns to stand out as an error
colorscheme ir_black     " Nice color scheme
syntax on                " Use syntax highlighting
"set foldmethod=syntax   " not set because it makes C++ unreadable. :'-(
set wildmode=longest,list:longest " Open tab completion
set wildmenu

"
" Map Q to paste the current X buffer (ordinarily: middle click /
" shift+Insert)
"
map Q "*p

" Yank to end of line.
map Y y$

" Do word wrapping for email
map ,w !} fmt -72 -c<CR>
map ,W !} fmt -200 -c<CR>

" quote a region for email
map ,q :s/^/> /g<CR>

source $HOME/.custom/vimrc

"
" Highlight lines longer than &textwidth
" From: https://wiki.corp.google.com/twiki/bin/view/Main/VimTips
"
function! HighlightTooLongLines()
  highlight def link RightMargin Error
  if &textwidth != 0
    exec 'match RightMargin /\%>' . &textwidth . 'v.\+/'
  endif
endfunction

augroup filetypedetect
au WinEnter,BufNewFile,BufRead * call HighlightTooLongLines()
augroup END

"
" When opening a previously opened file, move the cursor to the last
" position in the file.
"
:au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g'\"" | endif

""" Switch back and forth between: (credit David Reiss)
"         .h / -inl.h / .cc / .go / .py / .js / _test.* / _unittest.*
"  with   ,h / ,i     / ,c  / ,g  / ,p  / ,j  / ,t      / ,u
let pattern = '\(\(_\(unit\)\?test\)\?\.\(cc\|js\|py\|go\)\|\(-inl\)\?\.h\)$'
nmap ,c :e <C-R>=substitute(expand("%"), pattern, ".cc", "")<CR><CR>
nmap ,h :e <C-R>=substitute(expand("%"), pattern, ".h", "")<CR><CR>
nmap ,i :e <C-R>=substitute(expand("%"), pattern, "-inl.h", "")<CR><CR>
nmap ,t :e <C-R>=substitute(expand("%"), pattern, "_test.", "") . substitute(expand("%:e"), "h", "cc", "")<CR><CR>
nmap ,u :e <C-R>=substitute(expand("%"), pattern, "_unittest.", "") . substitute(expand("%:e"), "h", "cc", "")<CR><CR>
nmap ,g :e <C-R>=substitute(expand("%"), pattern, ".go", "")<CR><CR>
nmap ,p :e <C-R>=substitute(expand("%"), pattern, ".py", "")<CR><CR>
nmap ,j :e <C-R>=substitute(expand("%"), pattern, ".js", "")<CR><CR>

filetype off
filetype plugin indent off
set runtimepath+=/home/ekg/src/go/misc/vim
filetype plugin indent on
syntax on

autocmd BufNewFile -- fetch an otp over bluetooth and send it to the active window,BufRead *.go set tabstop=2
autocmd BufNewFile,BufRead *.go set noexpandtab
autocmd BufNewFile,BufRead *.go set nosmarttab
autocmd BufNewFile,BufRead *.go set nolist

au BufNewFile,BufRead *.swig set filetype=swig
autocmd BufNewFile,BufRead *.swig set textwidth=80

" Save automatically on focus lost (gvim).
au FocusLost * silent! wa

" hterm copy integration
" http://git.chromium.org/gitweb/?p=chromiumos/platform/assets.git;a=blob_plain;f=chromeapps/hterm/etc/osc52.vim
source ~/.vim/hterm.osc52.vim
vmap <C-c> y:call SendViaOSC52(getreg('"'))<cr>
