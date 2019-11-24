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

if exists('*trim')
  function! vista#util#Trim(str) abort
    return trim(a:str)
  endfunction
else
  function! vista#util#Trim(str) abort
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
  endfunction
endif

" Set the file path as the first line if possible.
function! s:PrependFpath(lines) abort
  if exists('t:vista.source.fpath')
    let width = winwidth(t:vista.winnr())
    let fpath = t:vista.source.fpath
    " Shorten the file path if it's too long
    if len(fpath) > width
      let fpath = '..'.fpath[len(fpath)-width+4 : ]
    endif
    return [fpath, ''] + a:lines
  endif

  return a:lines
endfunction

if has('nvim')
  function! s:SetBufline(bufnr, lines) abort
    call nvim_buf_set_lines(a:bufnr, 0, -1, 0, a:lines)
  endfunction

  function! vista#util#JobStop(jobid) abort
    silent! call jobstop(a:jobid)
  endfunction

else
  function! s:SetBufline(bufnr, lines) abort
    let cur_lines = getbufline(a:bufnr, 1, '$')
    call setbufline(a:bufnr, 1, a:lines)
    if len(cur_lines) > len(a:lines)
      silent call deletebufline(a:bufnr, len(a:lines)+1, len(cur_lines)+1)
    endif
  endfunction

  function! vista#util#JobStop(jobid) abort
    silent! call job_stop(a:jobid)
  endfunction
endif

function! vista#util#SetBufline(bufnr, lines) abort
  let lines = s:PrependFpath(a:lines)

  " This approach runes into the internal error E315.
  " I don't know why.
  " call s:SetBufline(a:bufnr, lines)

  let winnr = t:vista.winnr()
  if winnr() != winnr
    noautocmd execute winnr.'wincmd w'
    let l:switch_back = 1
  endif

  let bufnr = bufnr('')
  call setbufvar(bufnr, '&readonly', 0)
  call setbufvar(bufnr, '&modifiable', 1)

  silent 1,$delete _
  call setline(1, lines)

  call setbufvar(bufnr, '&readonly', 1)
  call setbufvar(bufnr, '&modifiable', 0)

  let filetype = vista#sidebar#WhichFileType()
  call setbufvar(bufnr, '&filetype', filetype)

  call vista#ftplugin#Set()
  " Reload vista syntax as you may switch between serveral
  " executives/extensions.
  "
  " rst shares the same syntax with vista_markdown.
  if t:vista.source.filetype() ==# 'rst'
    execute 'runtime! syntax/vista_markdown.vim'
  else
    execute 'runtime! syntax/'.filetype.'vim'
  endif

  if exists('l:switch_back')
    noautocmd wincmd p
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
function! vista#util#Blink(times, delay, ...) abort
  let s:blink = { 'ticks': 2 * a:times, 'delay': a:delay }
  let s:hi_pos = get(a:000, 0, line('.'))

  if !exists('#VistaBlink')
    augroup VistaBlink
      autocmd!
      autocmd BufWinEnter * call s:blink.clear()
    augroup END
  endif

  function! s:blink.tick(_) abort
    let self.ticks -= 1
    let active = self == s:blink && self.ticks > 0

    if !self.clear() && active && &hlsearch
      let w:vista_blink_id = matchaddpos('IncSearch', [s:hi_pos])
    endif
    if active
      call timer_start(self.delay, self.tick)
    endif
  endfunction

  function! s:blink.clear() abort
    if exists('w:vista_blink_id')
      call matchdelete(w:vista_blink_id)
      unlet w:vista_blink_id
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
      return get(found, a:ret_key, v:null)
    elseif array[mid][a:cmp_key] > target
      let high = mid - 1
    else
      let low = mid + 1
    endif
  endwhile

  if low == 0
    return v:null
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

  return get(found, a:ret_key, v:null)
endfunction

" CocAction only fetch symbols for current document, no way for specify the other at the moment.
" workaround for #52
"
" see also #71
function! vista#util#EnsureRunOnSourceFile(Run, ...) abort
  let source_winnr = t:vista.source.winnr()
  if winnr() != source_winnr
    execute source_winnr.'wincmd w'
    let l:switch_back = 1
  endif

  call call(a:Run, a:000)

  if exists('l:switch_back')
    wincmd p
  endif
endfunction

" Return the lines to preview and the target line number in the preview buffer.
function! vista#util#GetPreviewLines(lnum) abort
  " Show 5 lines around the tag source line [lnum-5, lnum+5]
  let range = 5

  if a:lnum - range > 0
    let preview_lnum = range + 1
  else
    let preview_lnum = a:lnum
  endif

  let begin = max([a:lnum - range, 1])
  let end = begin + range * 2

  return [getbufline(t:vista.source.bufnr, begin, end), preview_lnum]
endfunction
