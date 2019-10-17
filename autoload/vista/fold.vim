" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Treat the number of heading whitespaces as indent level
function! s:HeadingWhitespaces(line) abort
  return strlen(matchstr(a:line,'\v^\s+'))
endfunction

function! vista#fold#Expr() abort
  if getline(v:lnum) =~# '^$'
    return 0
  endif

  let cur_indent = s:HeadingWhitespaces(getline(v:lnum))
  let next_indent = s:HeadingWhitespaces(getline(v:lnum+1))

  if cur_indent < next_indent
    return '>'.next_indent
  else
    return cur_indent
  endif
endfunction

function! vista#fold#Text() abort
  let line = getline(v:foldstart)

  " Foldtext ignores tabstop and shows tabs as one space,
  " so convert tabs to 'tabstop' spaces, then text lines up.
  let spaces = repeat(' ', &tabstop)
  let line = substitute(line, '\t', spaces, 'g')
  let line = substitute(line, g:vista_fold_toggle_icons[0], g:vista_fold_toggle_icons[1], '')

  return line
endfunction
