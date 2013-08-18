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


