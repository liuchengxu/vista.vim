" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:floating_timer = -1
let s:last_lnum = -1

let s:floating_delay = get(g:, 'vista_floating_delay', 100)

" Vista sidebar window usually sits at the right side.
" TODO improve me!
function! s:CalculatePosition(lines) abort
  let lines = a:lines
  let pos = s:floating_opened_pos

  let width = max(map(copy(a:lines), 'strdisplaywidth(v:val)'))

  let width = max([width, 40])
  let width = min([width, float2nr(&columns * 0.6) ])
  let height = len(lines)

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

  let [_, _, cur_col, _, _] = getcurpos()

  " West first, fallback into East if there is no enough space.
  if pos[2] + width <= &columns
    let hor = hors[0]
    let col = 0
  else
    let hor = hors[1]
    let col = 1
  endif

  return [width, height, vert.hor, row-1, col+4-cur_col]
endfunction

function! s:ApplyClose() abort
  if !exists('g:vista')
    return
  endif

  if exists('#VistaFloatingWin')
    autocmd! VistaFloatingWin
  endif

  if exists('s:floating_win_id')
    let winnr = win_id2win(s:floating_win_id)

    if winnr > 0
      execute winnr.'wincmd c'
    endif
  endif

  let g:vista.floating_visible = v:false
endfunction

function! s:CloseOnCursorMoved() abort
  " To avoid closing floating window immediately, check the cursor
  " was really moved.
  if getpos('.') == s:floating_opened_pos
    return
  endif

  call s:ApplyClose()
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

  let g:vista.floating_visible = v:false
endfunction

function! s:HighlightTagInFloatinWin() abort
  if !nvim_win_is_valid(s:floating_win_id)
    return
  endif

  if exists('s:floating_lnum')
    let target_line = getbufline(s:floating_bufnr, s:floating_lnum)
    if empty(target_line)
      return
    endif
    let target_line = target_line[0]
    try
      let [_, start, end] = matchstrpos(target_line, '\C'.s:cur_tag)
      if start != -1
        " {line} is zero-based.
        call nvim_buf_add_highlight(s:floating_bufnr, -1, 'Search', s:floating_lnum-1, start, end)
      endif
    catch /^Vim\%((\a\+)\)\=:E869/
      " If we meet the E869 error, just highlight the whole line.
      call nvim_buf_add_highlight(s:floating_bufnr, -1, 'Search', s:floating_lnum-1, 0, -1)
    endtry

    unlet s:floating_lnum
  endif
endfunction

function! s:Display(msg, win_id) abort
  if a:win_id !=# win_getid()
    return
  endif

  if !exists('s:floating_bufnr') || !bufexists(s:floating_bufnr)
    let s:floating_bufnr = nvim_create_buf(v:false, v:false)
  endif

  let s:floating_opened_pos = getpos('.')
  let [width, height, anchor, row, col] = s:CalculatePosition(a:msg)

  let border = g:vista_floating_border

  " silent is neccessary for the both strategy!
  silent let s:floating_win_id = nvim_open_win(
        \ s:floating_bufnr, v:true, {
        \   'width': width,
        \   'height': height,
        \   'relative': 'cursor',
        \   'anchor': anchor,
        \   'row': row + 0.4,
        \   'col': col - 5,
        \   'focusable': v:false,
        \   'border': border,
        \ })

  call nvim_buf_set_lines(s:floating_bufnr, 0, -1, 0, a:msg)

  call s:HighlightTagInFloatinWin()

  let &l:filetype = getbufvar(g:vista.source.bufnr, '&ft')
  setlocal
        \ winhl=Normal:VistaFloat
        \ buftype=nofile
        \ nobuflisted
        \ bufhidden=hide
        \ nonumber
        \ norelativenumber
        \ signcolumn=no
        \ nofoldenable
        \ nospell
        \ wrap

  wincmd p

  augroup VistaFloatingWin
    autocmd!
    autocmd CursorMoved <buffer> call s:CloseOnCursorMoved()
    autocmd BufEnter,WinEnter,WinLeave  * call s:CloseOnWinEnter()
  augroup END

  let g:vista.floating_visible = v:true
endfunction

function! vista#floating#Close() abort
  call s:ApplyClose()
endfunction

" See if it's identical to the last lnum to avoid blink. Ref #55
"
" No need to display again when it's already visible.
function! s:ShouldSkipDisplay(lnum) abort
  silent! call timer_stop(s:floating_timer)

  if a:lnum == s:last_lnum
        \ && get(g:vista, 'floating_visible', v:false)
    return 1
  else
    let s:last_lnum = a:lnum
    return 0
  endif
endfunction

function! s:DisplayWithDelay(lines) abort
  let win_id = win_getid()
  let s:floating_timer = timer_start(s:floating_delay, { -> s:Display(a:lines, win_id)})
endfunction

" Display in floating_win given the lnum of source buffer and current tag.
function! vista#floating#DisplayAt(lnum, tag) abort
  if s:ShouldSkipDisplay(a:lnum)
    return
  endif

  " We save the tag info so that it could be used later for adding the tag highlight.
  "
  " It's problematic when calculating the highlight position here, leading to
  " the displacement of current tag highlighting position.
  let s:cur_tag = a:tag

  let [lines, s:floating_lnum] = vista#preview#GetLines(a:lnum)
  call s:DisplayWithDelay(lines)
endfunction

" Display in floating_win given the lnum of source buffer and raw lines.
function! vista#floating#DisplayRawAt(lnum, lines) abort
  if s:ShouldSkipDisplay(a:lnum)
    return
  endif

  call s:DisplayWithDelay(a:lines)
endfunction
