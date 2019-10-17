" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:last_lnum = -1
let s:popup_timer = -1

function! s:ClosePopup() abort
  if exists('s:popup_winid')
    call popup_hide(s:popup_winid)
    autocmd! VistaPopup
  endif
  let t:vista.popup_visible = v:false
endfunction

function! s:HiTag() abort
  call prop_type_delete('VistaMatch')
  call prop_type_add('VistaMatch', { 'highlight': 'Search' })
  call prop_add(s:popup_lnum, s:popup_start+1, { 'length': s:popup_end - s:popup_start, 'type': 'VistaMatch' })
endfunction

function! s:HiTagLine() abort
  if exists('w:vista_hi_cur_tag_id')
    call matchdelete(w:vista_hi_cur_tag_id)
  endif
  let w:vista_hi_cur_tag_id = matchaddpos('Search', [s:popup_lnum])
endfunction

function! s:OpenPopup(lines) abort
  if get(g:, 'vista_sidebar_position', 'vertical botright') =~# 'right'
    let pos_opts = {
          \ 'pos': 'botleft',
          \ 'line': 'cursor-2',
          \ 'col': 'cursor-'.s:max_length,
          \ 'moved': 'WORD',
          \ }
  else
    let winwidth = winwidth(0)
    let cur_length = strlen(getline('.'))
    let offset = min([cur_length + 4, winwidth])
    let col = 'cursor+'.offset
    let pos_opts = {
          \ 'pos': 'botleft',
          \ 'line': 'cursor-2',
          \ 'col': col,
          \ 'moved': 'WORD',
          \ }
  endif

  if !exists('s:popup_winid')
    let s:popup_winid = popup_create(a:lines, pos_opts)
    let s:popup_bufnr = winbufnr(s:popup_winid)

    let filetype = getbufvar(t:vista.source.bufnr, '&ft')
    call win_execute(s:popup_winid, 'setlocal filetype='.filetype.' nofoldenable')
  else
    silent call deletebufline(s:popup_bufnr, 1, '$')
    call setbufline(s:popup_bufnr, 1, a:lines)
    call popup_show(s:popup_winid)
    call popup_move(s:popup_winid, pos_opts)
  endif
endfunction

function! s:GetSouceLines(lnum) abort
  let range = 5

  if a:lnum - range > 0
    let s:popup_lnum = range + 1
  else
    let s:popup_lnum = a:lnum
  endif

  let begin = max([a:lnum - range, 1])
  let end = begin + range * 2

  return getbufline(t:vista.source.bufnr, begin, end)
endfunction

function! s:DisplayRawAt(lnum, lines) abort
  let s:max_length = max(map(copy(a:lines), 'strlen(v:val)')) + 2
  call s:OpenPopup(a:lines)

  augroup VistaPopup
    autocmd!
    autocmd CursorMoved <buffer> call s:ClosePopup()
    autocmd BufEnter,WinEnter,WinLeave  * call s:ClosePopup()
  augroup END

  let t:vista.popup_visible = v:true
endfunction

function! s:DisplayAt(lnum, tag) abort
  echom "000000 :".a:lnum." tag: .".a:tag
  let lines = s:GetSouceLines(a:lnum)

  let s:max_length = max(map(copy(lines), 'strlen(v:val)')) + 2

  call s:OpenPopup(lines)

  let target_line = lines[s:popup_lnum - 1]
  try
    echom "tag: ".a:tag
    let [_, s:popup_start, s:popup_end] = matchstrpos(target_line, '\C'.a:tag)

    " Highlight the tag in the popup window if found.
    if s:popup_start > -1
      echom "s:popup_move: ".s:popup_start
      call win_execute(s:popup_winid, 'call s:HiTag()')
    endif
  catch /^Vim\%((\a\+)\)\=:E869/
    call win_execute(s:popup_winid, 'call s:HiTagLine()')
  endtry

  augroup VistaPopup
    autocmd!
    autocmd CursorMoved <buffer> call s:ClosePopup()
    autocmd BufEnter,WinEnter,WinLeave * call s:ClosePopup()
  augroup END

  let t:vista.popup_visible = v:true
endfunction

function! vista#popup#Close() abort
  call s:ClosePopup()
endfunction

function! s:DispatchDisplayer(Displayer, lnum, tag_or_raw_lines) abort
  if a:lnum == s:last_lnum
        \ || get(t:vista, 'popup_visible', v:false)
    return
  endif

  silent! call timer_stop(s:popup_timer)

  let s:last_lnum = a:lnum

  let delay = get(g:, 'vista_floating_delay', 100)
  let s:popup_timer = timer_start(
        \ delay,
        \ { -> call(a:Displayer, [a:lnum, a:tag_or_raw_lines]) }
        \ )
endfunction

function! vista#popup#DisplayAt(lnum, tag) abort
  call s:DispatchDisplayer(function('s:DisplayAt'), a:lnum, a:tag)
endfunction

function! vista#popup#DisplayRawAt(lnum, lines) abort
  call s:DispatchDisplayer(function('s:DisplayRawAt'), a:lnum, a:lines)
endfunction
