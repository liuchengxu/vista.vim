" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! vista#statusline#ShouldDisable() abort
  return g:vista_disable_statusline
endfunction

function! vista#statusline#Render() abort
  if vista#statusline#ShouldDisable()
    return
  endif

  if has_key(g:vista, 'bufnr')
    call setbufvar(g:vista.bufnr, '&statusline', vista#statusline#())
  endif
endfunction

function! vista#statusline#RenderOnWinEvent() abort
  if !exists('g:vista') || vista#statusline#ShouldDisable()
    return
  endif

  let &l:statusline = vista#statusline#()
endfunction

function! vista#statusline#() abort
  let fname = get(g:vista.source, 'fname', '')
  let provider = get(g:vista, 'provider', '')
  if !empty(provider)
    return '[Vista] '.provider.' %<'.fname
  else
    return '[Vista] %<'.fname
  endif
endfunction
