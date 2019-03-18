" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! vista#source#Lines() abort
  return getbufline(t:vista.source.bufnr, 1, '$')
endfunction

function! vista#source#Line(lnum) abort
  let bufline = getbufline(t:vista.source.bufnr, a:lnum)
  return empty(bufline) ? '' : vista#util#Trim(bufline[0])
endfunction

function! vista#source#Extension() abort
  return fnamemodify(t:vista.source.fpath, ':e')
endfunction

function! vista#source#GotoWin() abort
  let winnr = t:vista.source.winnr
  noautocmd execute winnr."wincmd w"
  " Floating window relys on BufEnter event to be closed automatically.
  if exists('#VistaFloatingWin')
    doautocmd BufEnter VistaFloatingWin
  endif
endfunction

" Update the infomation of source file to be processed,
" including whose bufnr, winnr, fname, fpath
function! vista#source#Update(bufnr, winnr, ...) abort
  if !exists('t:vista')
    let t:vista = {}
  endif
  let t:vista.source = get(t:vista, 'source', {})
  let t:vista.source.bufnr = a:bufnr
  let t:vista.source.winnr = a:winnr

  if a:0 == 1
    let t:vista.source.fname = a:1
  elseif a:0 == 2
    let t:vista.source.fname = a:1
    let t:vista.source.fpath = a:2
  endif
endfunction
