" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:default_icon = ['╰─▸ ', '├─▸ ']

function! s:Render(data) abort
  if get(g:, 'vista_ctags_renderer', '') ==# 'default'
    return vista#renderer#default#Render()
  else
    return vista#renderer#kind#Render(a:data)
  endif
endfunction

" Render the extracted data to rows
function! vista#viewer#Render(data) abort
  return s:Render(a:data)
endfunction

function! vista#viewer#Display(data) abort
  call vista#sidebar#OpenOrUpdate(s:Render(a:data))
endfunction

function! vista#viewer#prefixes() abort
  return get(g:, 'vista_icon_indent', s:default_icon)
endfunction
