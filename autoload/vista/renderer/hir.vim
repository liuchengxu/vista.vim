" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:Transform(row) abort
  let indented = repeat(' ', a:row.level * 4).a:row.text
  let kind = ' : '.vista#renderer#Decorate(a:row.kind)
  let lnum = ':'.a:row.lnum
  return indented.kind.lnum
endfunction

" data is a list of items with the level info for the hierarchy purpose.
function! vista#renderer#hir#Coc(data) abort
  return map(a:data, 's:Transform(v:val)')
endfunction
