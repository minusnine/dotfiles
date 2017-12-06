set nocompatible               " be iMproved
filetype off                   " required!
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Bundle 'VundleVim/Vundle.vim'
Bundle 'gmarik/vundle'
Bundle 'scrooloose/syntastic'
Bundle 'myusuf3/numbers.vim'
Bundle 'flazz/vim-colorschemes'
Bundle 'fatih/vim-go'
Bundle 'Valloric/YouCompleteMe'
call vundle#end()
filetype plugin indent on

set autoindent           " Preserve current indent on new lines
set backspace=indent,eol,start    "Make backspaces delete sensibly
set backup               " keep backups of files when overwriting them
set backupdir=~/tmp/vim// " keep backups in this directory
set undofile  " keep an undo file (undo changes after closing)
set undodir=~/tmp/vim//
set directory=~/tmp/vim// " put swap files in this directory
set expandtab            " Convert all tabs typed to spaces
set modeline             " look for modelines in the first 10 lines
set modelines=10         " ibid
set number
set ruler                " Display cursor line number and column in the status bar
set shiftround           " Indent/outdent to nearest tabstop
set shiftwidth=2         " Indent/outdent by two columns
set showmatch            " Highlight matching braces
set smartindent          " Indent smartly
set smarttab             " do the right thing with tabs
set softtabstop=2        " Number of spaces that a tab counts for
set t_Co=256             " Use 256 colors
set tabstop=2            " Tabs use eight columns to stand out as an error
colorscheme ir_black     " Nice color scheme
syntax on                " Use syntax highlighting

let g:go_fmt_command = "goimports"
let g:ycm_python_binary_path = '/usr/bin/python3'
let g:ycm_server_python_interpreter = '/usr/bin/python'

" Close the preview window after insert mode is left.
"
" https://github.com/Valloric/YouCompleteMe#the-gycm_add_preview_to_completeopt-option
let g:ycm_autoclose_preview_window_after_insertion = 1

" Remember the last position in the file.
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_go_checkers = ['go', 'gofmt', 'govet']
