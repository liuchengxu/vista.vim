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
  let explicit_executive = vista#GetExplicitExecutive(&filetype)
  if explicit_executive isnot v:null
    call vista#executive#{explicit_executive}#Execute(v:false, v:true, v:false)
  else
    if index(['markdown', 'vimwiki', 'pandoc', 'apiblueprint'], &filetype) > -1
      let extension = 'markdown'
    else
      let extension = &filetype
    endif
    if index(g:vista#extensions, extension) > -1
      call vista#extension#{extension}#Execute(v:false, v:true)
    else
      call vista#error#('Cannot find vista extension: '.extension)
    endif
  endif
endfunction
