" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

if exists('*bufwinid')
  function! s:GotoSourceWindow() abort
    let bufid = g:vista.source.bufnr
    let winid = bufwinid(bufid)
    if winid != -1
      if win_getid() != winid
        " No use noautocmd here. Ref #362
        call win_gotoid(winid)
      endif
    else
      return vista#error#('Cannot find the source window id')
    endif
  endfunction
else
  function! s:GotoSourceWindow() abort
    " g:vista.source.winnr is not always correct.
    let winnr = g:vista.source.get_winnr()
    if winnr != -1
      execute winnr.'wincmd w'
    else
      return vista#error#('Cannot find the target window')
    endif
  endfunction
endif

function! vista#source#GotoWin() abort
  let g:vista.skip_once_flag = v:true
  call s:GotoSourceWindow()

  " Floating window relys on BufEnter event to be closed automatically.
  if exists('#VistaFloatingWin')
    doautocmd BufEnter VistaFloatingWin
  endif
endfunction

" Update the infomation of source file to be processed,
" including whose bufnr, winnr, fname, fpath
function! vista#source#Update(bufnr, winnr, ...) abort
  if !exists('g:vista')
    call vista#init#Api()
  endif

  let g:vista.source.bufnr = a:bufnr
  let g:vista.source.winnr = a:winnr

  if a:0 == 1
    let g:vista.source.fname = a:1
  elseif a:0 == 2
    let g:vista.source.fname = a:1
    let g:vista.source.fpath = a:2
  endif
endfunction

function! s:ApplyPeek(lnum, tag) abort
  silent execute 'normal!' a:lnum.'z.'
  let [_, start, _] = matchstrpos(getline('.'), a:tag)
  call vista#util#Blink(1, 100, [a:lnum, start+1, strlen(a:tag)])
endfunction

if exists('*win_execute')
  function! vista#source#PeekSymbol(lnum, tag) abort
    call win_execute(g:vista.source.winid, 'noautocmd call s:ApplyPeek(a:lnum, a:tag)')
  endfunction
else
  function! vista#source#PeekSymbol(lnum, tag) abort
    call vista#win#Execute(g:vista.source.get_winnr(), function('s:ApplyPeek'), a:lnum, a:tag)
  endfunction
endif
