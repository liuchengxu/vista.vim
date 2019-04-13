" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:floating_timer = -1
let s:last_lnum = -1

" Vista sidebar window usually sits at the right side.
" TODO improve me!
function! s:CalculatePosition(lines) abort
  let lines = a:lines
  let pos = s:floating_opened_pos

  let width = -1

  for idx in range(len(lines))
    let line = lines[idx]
    let w = strdisplaywidth(line)
    if w > width
      let width = w
    endif
  endfor

  let width = width > 40 ? width : 40

  let height = len(lines)

  let height = height > 10 ? height : 10

  " Calculate anchor
  " North first, fallback to South if there is no enough space.
  let bottom_line = line('w0') + winheight(0) - 1
  if pos[1] + height <= bottom_line
    let vert = 'N'
    let row = 1
  else
    let vert = 'S'
    let row = 0
  endif

  " TODO should be tweaked accroding to the position of vista sidebar
  let hors = ['E', 'W']

  " West first, fallback into East if there is no enough space.
  if pos[2] + width <= &columns
    let hor = hors[0]
    let col = 0
  else
    let hor = hors[1]
    let col = 1
  endif

  return [width, height, vert.hor, row, col]
endfunction

function! s:CloseOnCursorMoved() abort
  " To avoid closing floating window immediately, check the cursor
  " was really moved.
  if getpos('.') == s:floating_opened_pos
    return
  endif

  autocmd! VistaFloatingWin

  let winnr = win_id2win(s:floating_win_id)

  if winnr == 0
    return
  endif

  execute winnr.'wincmd c'
endfunction

function! s:CloseOnWinEnter() abort
  let winnr = win_id2win(s:floating_win_id)

  " Floating window has been closed already.
  if winnr == 0
    autocmd! VistaFloatingWin
    return
  endif

  " We are just in the floating window. Do not close it
  if winnr == winnr()
    return
  endif

  autocmd! VistaFloatingWin
  execute winnr.'wincmd c'
endfunction

function! s:Display(msg) abort
  let msg = a:msg

  if !exists('s:floating_bufnr') || !bufexists(s:floating_bufnr)
    let s:floating_bufnr = nvim_create_buf(v:false, v:false)
  endif

  let s:floating_opened_pos = getpos('.')
  let [width, height, anchor, row, col] = s:CalculatePosition(a:msg)

  " silent is neccessary for the both strategy!
  silent let s:floating_win_id = nvim_open_win(
        \ s:floating_bufnr, v:true, {
        \   'width': width,
        \   'height': height,
        \   'relative': 'cursor',
        \   'anchor': anchor,
        \   'row': row + 0.4,
        \   'col': col - 5,
        \ })

  call nvim_buf_set_lines(s:floating_bufnr, 0, -1, 0, a:msg)

  " FIXME current highlight is problematic.
  if exists('s:start')
    call nvim_buf_add_highlight(s:floating_bufnr, -1, 'Search', s:lnum, s:start, s:end)
  endif

  setlocal
        \ winhl=Normal:Pmenu
        \ buftype=nofile
        \ nobuflisted
        \ bufhidden=hide
        \ nonumber
        \ norelativenumber
        \ signcolumn=no

  let &l:filetype = getbufvar(t:vista.source.bufnr, '&ft')

  wincmd p

  augroup VistaFloatingWin
    autocmd!
    autocmd CursorMoved <buffer> call s:CloseOnCursorMoved()
    autocmd BufEnter,WinEnter,WinLeave  * call s:CloseOnWinEnter()
  augroup END
endfunction

function! vista#floating#Display(lnum, tag) abort
  silent! call timer_stop(s:floating_timer)
  silent! unlet s:start s:end s:lnum

  let lnum = a:lnum

  if lnum == s:last_lnum
    return
  endif

  let s:last_lnum = lnum

  let [_, start, end] = matchstrpos(t:vista.source.line(lnum), '\C'.a:tag)

  if start != -1
    let [s:start, s:end] = [start, end]
  endif

  " FIXME correct tag height
  let s:lnum = lnum < 6 ? lnum : 5

  let begin = max([lnum - 5, 1])
  let end = begin + 5 * 2
  let lines = getbufline(t:vista.source.bufnr, begin, end)

  " TODO the msg could be more fruitful when using floating window
  let delay = get(g:, 'vista_floating_delay', 100)
  let s:floating_timer = timer_start(
        \ delay,
        \ { -> s:Display(lines)},
        \ )
endfunction
