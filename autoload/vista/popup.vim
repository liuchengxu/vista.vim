" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:last_lnum = -1

function! s:ClosePopup() abort
  if exists('s:popup_winid')
    call popup_close(s:popup_winid)
    autocmd! VistaPopup
    unlet s:popup_winid
  endif
endfunction

function! s:HiTag() abort
  call prop_type_delete('VistaMatch')
  call prop_type_add('VistaMatch', { 'highlight': 'Search' })
  call prop_add(s:popup_lnum, s:popup_start+1, { 'length': s:popup_end - s:popup_start, 'type': 'VistaMatch' })
endfunction

function! s:OpenPopup(lnum, tag) abort
  let range = 5

  if a:lnum - range > 0
    let s:popup_lnum = range + 1
  else
    let s:popup_lnum = a:lnum
  endif

  let begin = max([a:lnum - range, 1])
  let end = begin + range * 2
  let lines = getbufline(t:vista.source.bufnr, begin, end)

  let max_length = max(map(copy(lines), 'strlen(v:val)')) + 2

  let s:popup_winid = popup_create(lines, {
        \ 'pos': 'botleft',
        \ 'line': 'cursor-2',
        \ 'col': 'cursor-'.max_length,
        \ 'moved': 'WORD',
        \ })

  let filetype = getbufvar(t:vista.source.bufnr, '&ft')
  call win_execute(s:popup_winid, 'setlocal filetype='.filetype)

  let target_line = lines[s:popup_lnum - 1]
  let [_, s:popup_start, s:popup_end] = matchstrpos(target_line, '\C'.a:tag)

  call win_execute(s:popup_winid, 'call s:HiTag()')

  augroup VistaPopup
    autocmd!
    autocmd CursorMoved <buffer> call s:ClosePopup()
    autocmd BufEnter,WinEnter,WinLeave  * call s:ClosePopup()
  augroup END
endfunction

function! vista#popup#Close() abort
  call s:ClosePopup()
endfunction

function! vista#popup#Display(lnum, tag) abort
  if a:lnum == s:last_lnum
    return
  endif
  let s:last_lnum = a:lnum
  call s:OpenPopup(a:lnum, a:tag)
endfunction
