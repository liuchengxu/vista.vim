" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:other_statusline_plugin_loaded = exists('g:loaded_airline') || exists('g:loaded_lightline')

function! vista#statusline#ShouldDisable() abort
  return get(g:, 'vista_disable_statusline', s:other_statusline_plugin_loaded)
endfunction

function! vista#statusline#Render() abort
  if vista#statusline#ShouldDisable()
    return
  endif

  if has_key(t:vista, 'bufnr')
    call setbufvar(t:vista.bufnr, '&statusline', vista#statusline#())
  endif
endfunction

function! vista#statusline#RenderOnWinEvent() abort
  if !exists('t:vista') || vista#statusline#ShouldDisable()
    return
  endif

  let &l:statusline = vista#statusline#()
endfunction

function! vista#statusline#() abort
  let fname = get(t:vista.source, 'fname', '')
  let provider = get(t:vista, 'provider', '')
  if !empty(provider)
    return '[Vista] '.provider.' %<'.fname
  else
    return '[Vista] %<'.fname
  endif
endfunction
