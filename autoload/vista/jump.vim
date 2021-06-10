" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:EscapeForVimRegexp(str) abort
  return escape(a:str, '^$.*?/\[]')
endfunction

" Jump to the source line containing the given tag
function! vista#jump#TagLine(tag) abort
  let cur_line = split(getline('.'), ':')

  " Skip if the current line or the target line is empty
  if empty(cur_line)
    return
  endif

  let lnum = cur_line[-1]
  let line = getbufline(g:vista.source.bufnr, lnum)

  if empty(line)
    return
  endif

  try
    let [_, start, _] = matchstrpos(line[0], s:EscapeForVimRegexp(a:tag))
  catch /^Vim\%((\a\+)\)\=:E869/
    let start  = -1
  endtry

  call vista#source#GotoWin()
  " Move cursor to the column of tag located, otherwise the first column
  call vista#util#Cursor(lnum, start > -1 ? start+1 : 1)

  if g:vista_enable_centering_jump
    normal! zz
  endif

  call call('vista#util#Blink', g:vista_blink)

  call vista#win#CloseFloating()

  if g:vista_close_on_jump
    call vista#sidebar#Close()
  endif
endfunction

function! s:NextTopLevelLnum() abort
  let cur_lnum = line('.')
  let ending = line('$')

  while cur_lnum < ending
    let cur_lnum += 1
    if indent(cur_lnum) == 0 && !empty(getline(cur_lnum))
      return cur_lnum
    endif
  endwhile

  return 0
endfunction

function! s:PrevTopLevelLnum() abort
  let cur_lnum = line('.')

  " The first two lines contain no tags.
  while cur_lnum > 2
    let cur_lnum -= 1
    if indent(cur_lnum) == 0 && !empty(getline(cur_lnum))
      return cur_lnum
    endif
  endwhile

  if cur_lnum == 3
    return 3
  endif

  return 0
endfunction

function! s:ApplyJump(lnum) abort
  if a:lnum > 0
    call vista#util#Cursor(a:lnum, 1)
    normal! zz
    call call('vista#util#Blink', g:vista_top_level_blink)
  endif
endfunction

function! vista#jump#NextTopLevel() abort
  call vista#win#CloseFloating()
  call s:ApplyJump(s:NextTopLevelLnum())
endfunction

function! vista#jump#PrevTopLevel() abort
  call vista#win#CloseFloating()
  call s:ApplyJump(s:PrevTopLevelLnum())
endfunction
