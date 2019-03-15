" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! vista#util#MaxLen() abort
  let l:maxlen = &columns * &cmdheight - 2
  let l:maxlen = &showcmd ? l:maxlen - 11 : l:maxlen
  let l:maxlen = &ruler ? l:maxlen - 18 : l:maxlen
  return l:maxlen
endfunction

" Avoid hit-enter prompt when the message being echoed is too long.
function! vista#util#Truncate(msg) abort
  let maxlen = vista#util#MaxLen()
  return len(a:msg) < maxlen ? a:msg : a:msg[:maxlen-3].'...'
endfunction

function! vista#util#Trim(str)
  if exists('*trim')
    return trim(a:str)
  else
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
  endif
endfunction

" Set the file path as the first line if possible.
function! s:PrependFpath(lines) abort
  if exists('t:vista.source.fpath')
    let width = &l:winwidth
    let fpath = t:vista.source.fpath
    " Shorten the file path if it's too long
    if len(fpath) > width
      let fpath = '..'.fpath[len(fpath)-width:]
      let lines = [fpath, ''] + a:lines
      return lines
    endif
  endif

  return a:lines
endfunction

function! vista#util#SetBufline(bufnr, lines) abort
  setlocal noreadonly modifiable
  let lines = s:PrependFpath(a:lines)
  if has('nvim')
    call nvim_buf_set_lines(a:bufnr, 0, -1, 0, lines)
  else
    call setbufline(a:bufnr, 1, lines)
  endif
  setlocal readonly nomodifiable
endfunction

function! vista#util#JobStop(jobid) abort
  if has('nvim')
    silent! call jobstop(a:jobid)
  else
    silent! call job_stop(a:jobid)
  endif
endfunction

" Blink current line under cursor, from junegunn/vim-slash
function! vista#util#Blink(times, delay) abort
  let s:blink = { 'ticks': 2 * a:times, 'delay': a:delay }

  function! s:blink.tick(_)
    let self.ticks -= 1
    let active = self == s:blink && self.ticks > 0

    if !self.clear() && active && &hlsearch
      let w:blink_id = matchaddpos('IncSearch', [line('.')])
    endif
    if active
      call timer_start(self.delay, self.tick)
    endif
  endfunction

  function! s:blink.clear()
    if exists('w:blink_id')
      call matchdelete(w:blink_id)
      unlet w:blink_id
      return 1
    endif
  endfunction

  call s:blink.clear()
  call s:blink.tick(0)
  return ''
endfunction

function! vista#util#Warning(msg) abort
  echohl WarningMsg
  echom  '[vista.vim] '.a:msg
  echohl NONE
endfunction

function! vista#util#Complete(A, L, P) abort
  let cmd = ['coc', 'ctags', 'finder']
  let args = split(a:L)
  if !empty(args) && args[-1] == 'finder'
    return join(['coc', 'ctags'], "\n")
  endif
  return join(cmd, "\n")
endfunction

" Return the lower indent line number
function! vista#util#LowerIndentLineNr() abort
  let linenr = line('.')
  let indent = indent(linenr)
  while linenr > 0
    let linenr -= 1
    if indent(linenr) < indent
      return linenr
    endif
  endwhile
  return 0
endfunction
