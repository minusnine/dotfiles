"
" When opening a previously opened file, move the cursor to the last
" position in the file.
"
:au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g'\"" | endif


