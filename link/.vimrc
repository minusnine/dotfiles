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

" Do word wrapping for email
map ,w !} fmt -72 -c<CR>
map ,W !} fmt -200 -c<CR>
