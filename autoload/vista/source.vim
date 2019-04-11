" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:use_winid = exists('*bufwinid')

function! s:EnsureExists() abort
  if !exists('t:vista')
    let t:vista = {}
    function! t:vista.winnr() abort
      return bufwinnr('__vista__')
    endfunction
  endif

  if !has_key(t:vista, 'source')
    let t:vista.source = {}

    function! t:vista.source.winnr() abort
      return bufwinnr(self.bufnr)
    endfunction

    function! t:vista.source.winid() abort
      return bufwinid(self.bufnr)
    endfunction

    function! t:vista.source.filetype() abort
      return getbufvar(self.bufnr, '&filetype')
    endfunction

    function! t:vista.source.lines() abort
      return getbufline(self.bufnr, 1, '$')
    endfunction

    function! t:vista.source.line(lnum) abort
      let bufline = getbufline(self.bufnr, a:lnum)
      return empty(bufline) ? '' : vista#util#Trim(bufline[0])
    endfunction

    function! t:vista.source.extension() abort
      return fnamemodify(self.fpath, ':e')
    endfunction
  endif
endfunction

function! vista#source#GotoWin() abort
  if s:use_winid
    let winid = t:vista.source.winid()
    if winid != -1
      call win_gotoid(winid)
    else
      return vista#error#('Cannot find the source window id')
    endif
  else
    " t:vista.source.winnr is not always correct.
    let winnr = t:vista.source.winnr()
    if winnr != -1
      noautocmd execute winnr.'wincmd w'
    else
      return vista#error#('Cannot find the target window')
    endif
  endif
  " Floating window relys on BufEnter event to be closed automatically.
  if exists('#VistaFloatingWin')
    doautocmd BufEnter VistaFloatingWin
  endif
endfunction

" Update the infomation of source file to be processed,
" including whose bufnr, winnr, fname, fpath
function! vista#source#Update(bufnr, winnr, ...) abort
  if !exists('t:_vista_initialized')
    call s:EnsureExists()
    let t:_vista_initialized = 1
  endif

  let t:vista.source.bufnr = a:bufnr

  if a:0 == 1
    let t:vista.source.fname = a:1
  elseif a:0 == 2
    let t:vista.source.fname = a:1
    let t:vista.source.fpath = a:2
  endif
endfunction
