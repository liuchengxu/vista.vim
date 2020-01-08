let s:find_timer = -1
let s:hi_timer = -1

function! s:StopFindTimer() abort
  if s:find_timer != -1
    call timer_stop(s:find_timer)
  endif
endfunction

function! vista#cursor#lsp#GetInfoUnderCursor() abort
  if has_key(t:vista, 'lnum2tag')
    return [t:vista.lnum2tag[line('.')], v:true]
  endif
endfunction

function! s:HiNearestSymbol(_timer) abort
  if !exists('t:vista')
    return
  endif
  let winnr = t:vista.winnr()

  if has_key(t:vista.slnum2tlnum, line('.'))
    let tlnum = t:vista.slnum2tlnum[line('.')]
    call vista#WinExecute(winnr, function('vista#cursor#Hi'), tlnum, v:true)
  endif
endfunction

function! vista#cursor#lsp#HiNearestSymbol() abort
  if s:hi_timer != -1
    call timer_stop(s:hi_timer)
  endif

  if vista#sidebar#IsVisible()
    let s:hi_timer = timer_start(200, function('s:HiNearestSymbol'))
  endif
  return
endfunction
