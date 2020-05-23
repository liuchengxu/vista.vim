" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" vimwiki supports the standard markdown syntax.
" pandoc supports the basic markdown format.
" API Blueprint is a set of semantic assumptions on top of markdown.
let s:toc_supported = ['markdown', 'rst', 'vimwiki', 'pandoc', 'apiblueprint']

function! vista#toc#IsSupported(filetype) abort
  return index(s:toc_supported, a:filetype) > -1
endfunction

" toc is the synonym of markdown like extensions.
function! vista#toc#Run() abort
  let executive = vista#GetExplicitExecutiveOrDefault()
  if executive ==# 'toc'
    let extension = &filetype
  else
    let extension = executive
  endif
  if index(g:vista#extensions, extension) > -1
    call vista#extension#{extension}#Execute(v:false, v:true)
  else
    call vista#executive#{executive}#Execute(v:false, v:true, v:false)
  endif
endfunction
