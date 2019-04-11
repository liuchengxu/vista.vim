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

function! vista#util#Trim(str) abort
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
      let fpath = '..'.fpath[len(fpath)-width : ]
    endif
    return [fpath, ''] + a:lines
  endif

  return a:lines
endfunction

function! vista#util#SetBufline(bufnr, lines) abort
  call setbufvar(a:bufnr, '&readonly', 0)
  call setbufvar(a:bufnr, '&modifiable', 1)
  let lines = s:PrependFpath(a:lines)
  if has('nvim')
    call nvim_buf_set_lines(a:bufnr, 0, -1, 0, lines)
  else
    let cur_lines = getbufline(a:bufnr, 1, '$')
    call setbufline(a:bufnr, 1, lines)
    if len(cur_lines) > len(lines)
      call deletebufline(a:bufnr, len(lines)+1, len(cur_lines)+1)
    endif
  endif
  call setbufvar(a:bufnr, '&readonly', 1)
  call setbufvar(a:bufnr, '&modifiable', 0)
endfunction

function! vista#util#JobStop(jobid) abort
  if has('nvim')
    silent! call jobstop(a:jobid)
  else
    silent! call job_stop(a:jobid)
  endif
endfunction

function! vista#util#Join(...) abort
  return join(a:000, '')
endfunction

" Change coc, ctags, lcn, vim_lsp to Coc, Ctags, Lcn, VimLsp
function! vista#util#ToCamelCase(s) abort
  return substitute(a:s, '\(^\l\+\)\|_\(\l\+\)', '\u\1\2', 'g')
endfunction

" Blink current line under cursor, from junegunn/vim-slash
function! vista#util#Blink(times, delay) abort
  let s:blink = { 'ticks': 2 * a:times, 'delay': a:delay }

  function! s:blink.tick(_) abort
    let self.ticks -= 1
    let active = self == s:blink && self.ticks > 0

    if !self.clear() && active && &hlsearch
      let w:blink_id = matchaddpos('IncSearch', [line('.')])
    endif
    if active
      call timer_start(self.delay, self.tick)
    endif
  endfunction

  function! s:blink.clear() abort
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

function! vista#util#Retriving(executive) abort
  echohl WarningMsg
  echom '[Vista.vim] '
  echohl NONE

  echohl Function
  echon a:executive
  echohl NONE

  echohl Type
  echon  ' is retriving symbols ..., please try again later'
  echohl NONE
endfunction

function! vista#util#Complete(A, L, P) abort
  let cmd = ['coc', 'ctags', 'finder']
  let args = split(a:L)
  if !empty(args) && args[-1] ==# 'finder'
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

" array: List of Dict, composed of Method or Function symbols
" target: current line number in the source buffer
function! vista#util#BinarySearch(array, target, cmp_key, ret_key) abort
  let [array, target] = [a:array, a:target]

  let low = 0
  let high = len(array) - 1

  while low <= high
    let mid = (low + high) / 2
    if array[mid][a:cmp_key] == target
      let found = array[mid]
      return found[a:ret_key]
    elseif array[mid][a:cmp_key] > target
      let high = mid - 1
    else
      let low = mid + 1
    endif
  endwhile

  if low == 0
    return ''
  endif

  " If no exact match, prefer the previous nearest one.
  if get(g:, 'vista_find_absolute_nearest_method_or_function', 0)
    if abs(array[low][a:cmp_key] - target) < abs(array[low - 1][a:cmp_key] - target)
      let found = array[low]
    else
      let found = array[low - 1]
    endif
  else
    let found = array[low - 1]
  endif

  return found[a:ret_key]
endfunction
