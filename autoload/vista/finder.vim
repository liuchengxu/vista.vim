" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Could use the cached data?
function! s:IsUsable(cache, fpath) abort
  return !empty(a:cache)
        \ && has_key(a:cache, a:fpath)
        \ && getftime(a:fpath) == a:cache.ftime
        \ && !getbufvar(a:cache.bufnr, '&mod')
endfunction

" Try other alternative executives when the data given by the specified one is empty.
" Return v:true if some alternative brings us some data, or else v:false.
function! s:TryAlternatives(tried, fpath) abort
  " TODO when more executives added allow configuring this list
  let executives = get(g:, 'vista_finder_alternative_executives', g:vista#executives)

  if empty(executives)
    return v:false
  endif

  let alternatives = filter(copy(executives), 'v:val != a:tried')

  for alternative in alternatives
    let s:data = vista#executive#{alternative}#Run(a:fpath)
    if !empty(s:data)
      let s:cur_executive = alternative
      let s:using_alternative = v:true
      return v:true
    endif
  endfor

  return v:false
endfunction

function! vista#finder#GetSymbols(...) abort
  let executive = a:0 > 0 ? a:1 : get(g:, 'vista_default_executive', 'ctags')

  if index(g:vista#executives, executive) == -1
    call vista#error#InvalidExecutive(executive)
    return
  endif

  let cache = vista#executive#{executive}#Cache()
  let skip = vista#ShouldSkip()
  if skip
    let t:vista.source = get(t:vista, 'source', {})
    let fpath = t:vista.source.fpath
  else
    let fpath = expand('%:p')
  endif

  if s:IsUsable(cache, fpath)
    let s:data = cache[fpath]
  else
    if !skip
      let [bufnr, winnr, fname] = [bufnr('%'), winnr(), expand('%')]
      call vista#source#Update(bufnr, winnr, fname, fpath)
    endif
    let t:vista.skip_set_provider = v:true
    " In this case, we normally want to run synchronously IMO.
    let s:data = vista#executive#{executive}#Run(fpath)
  endif

  let s:cur_executive = executive
  let s:using_alternative = v:false

  if empty(s:data) && !s:TryAlternatives(executive, fpath)
    return [v:null, s:cur_executive, s:using_alternative]
  endif

  return [s:data, s:cur_executive, s:using_alternative]
endfunction
