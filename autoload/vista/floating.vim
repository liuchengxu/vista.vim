" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:floating_timer = -1

" Vista sidebar window usually sits at the right side.
function! s:CalculatePosition(lines, pos) abort
  let lines = a:lines
  let pos = a:pos

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

  " West first, fallback into East if there is no enough space.
  if pos[2] + width <= &columns
    let hor = 'W'
    let col = 0
  else
    let hor = 'E'
    let col = 1
  endif

  return [width, height, vert.hor, row, col]
endfunction

function! s:CloseOnCursorMoved() abort
  if exists('s:floating_win_id')
    " To avoid closing floating window immediately, check the cursor
    " was really moved
    if getpos('.') == s:floating_opened_pos
      return
    endif

    autocmd! VistaFloatingWin

    let winnr = win_id2win(s:floating_win_id)

    if winnr == 0
      return
    endif

    execute winnr.'wincmd c'
    unlet s:floating_win_id
  endif
endfunction

function! s:CloseOnWinEnter() abort
  if exists('s:floating_win_id')
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
    unlet s:floating_win_id
  endif
endfunction

function! s:Display(msg) abort
  let msg = a:msg

  let s:floating_opened_pos = getpos('.')

  if !exists('s:floating_bufnr') || !bufexists(s:floating_bufnr)
    let s:floating_bufnr = nvim_create_buf(v:false, v:false)
  endif

  let [width, height, anchor, row, col] = s:CalculatePosition([a:msg], s:floating_opened_pos)

  let s:floating_win_id = nvim_open_win(
        \ s:floating_bufnr, v:true, width, height, {
        \   'relative': 'cursor',
        \   'anchor': anchor,
        \   'row': row + 0.4,
        \   'col': col - 5,
        \ })

  call nvim_buf_set_lines(s:floating_bufnr, 0, -1, 0, [a:msg])

  setlocal number
  setlocal
        \ winhl=Normal:Pmenu
        \ buftype=nofile
        \ nobuflisted
        \ bufhidden=hide
        \ norelativenumber
        \ signcolumn=no

  let &l:filetype = getbufvar(t:vista.source.bufnr, '&ft')

  wincmd p

  augroup VistaFloatingWin
    autocmd!
    autocmd CursorMoved <buffer> call s:CloseOnCursorMoved()
    autocmd WinEnter * call s:CloseOnWinEnter()
  augroup END
endfunction

function! vista#floating#Display(msg) abort
  silent! call timer_stop(s:floating_timer)

  " TODO the msg could be more fruitful when using floating window
  let delay = get(g:, 'vista_floating_delay', 100)
  let s:floating_timer = timer_start(
        \ delay,
        \ { -> s:Display(a:msg)},
        \ )
endfunction
