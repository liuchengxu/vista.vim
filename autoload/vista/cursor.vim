" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:cursor_timer = -1

function! s:StopCursorTimer() abort
  if s:cursor_timer != -1
    call timer_stop(s:cursor_timer)
    let s:cursor_timer = -1
  endif
endfunction

" Get tag and corresponding source line at current cursor position.
" Return: [tag, line]
function! s:GetInfoUnderCursor() abort
  let cur_line = split(getline('.'), ':')

  if empty(cur_line)
    return [v:null, v:null]
  endif

  let lnum = cur_line[-1]

  let source_line = vista#source#Line(lnum)
  if empty(source_line)
    return [v:null, v:null]
  endif

  let with_tag = split(cur_line[-2])
  if empty(with_tag)
    return [v:null, v:null]
  endif

  let tag = with_tag[-1]

  return [tag, source_line]
endfunction

" Echo the tag with detailed info in the cmdline
function! s:EchoInCmdline(msg, tag) abort
  let [msg, tag] = [a:msg, a:tag]

  let [_, start, end] = matchstrpos(msg, '\C'.tag)

  " If couldn't find the tag in the msg
  if start == -1
    echohl Function | echo msg | echohl NONE
    return
  endif

  " Try highlighting the scope of current tag
  let linenr = vista#util#LowerIndentLineNr()

  " Echo the scope of current tag if found
  if linenr != 0
    let pieces = split(getline(linenr), ' ')
    if !empty(pieces)
      let scope = pieces[1]
      echohl Function  | echo '['.scope.'] '  | echohl NONE
      echohl Statement | echon msg[0:start-1] | echohl NONE
    endif
  else
    echohl Statement | echo msg[0:start-1] | echohl NONE
  endif

  echohl Search    | echon msg[start:end-1] | echohl NONE
  echohl Statement | echon msg[end:]        | echohl NONE
endfunction

" Show the detail of current tag/symbol under cursor.
function! s:ShowDetail() abort
  let [tag, line] = s:GetInfoUnderCursor()

  if empty(tag) || empty(line)
    echo "\r"
    return
  endif

  let msg = vista#util#Truncate(line)

  if exists('*nvim_open_win')
    silent! call timer_stop(s:floating_timer)

    " TODO the msg could be more fruitful when using floating window
    let delay = get(g:, 'vista_floating_delay', 100)
    let s:floating_timer = timer_start(
          \ delay,
          \ { -> vista#floating#Display(msg)},
          \ )
  else
    call s:EchoInCmdline(msg, tag)
  endif
endfunction

function! vista#cursor#ShowDetail(_timer) abort
  let cur_line = getline('.')
  if empty(cur_line)
    return
  endif

  " scope line
  if cur_line[-1:] ==# ']'
    let splitted = split(cur_line)
    " Join the scope parts in case of they contains spaces, e.g., structure names 
    let scope = join(splitted[1:-2], ' ')
    let count = matchstr(splitted[-1], '\d\+') 
    echohl Keyword  | echo '['.scope.']: ' | echohl NONE
    echohl Function | echon count          | echohl NONE
    return
  endif

  call s:ShowDetail()
endfunction

function! vista#cursor#ShowDetailWithDelay() abort
  call s:StopCursorTimer()

  let delay = get(g:, 'vista_cursor_delay', 400)
  let s:cursor_timer = timer_start(
        \ delay,
        \ function('vista#cursor#ShowDetail'),
        \ )
endfunction

function! s:Jump() abort
  let cur_line = split(getline('.'), ':')

  " Skip if the current line or the target line is empty
  if empty(cur_line)
    return
  endif

  let lnum = cur_line[-1]
  let line = getbufline(t:vista.source.bufnr, lnum)

  if empty(line)
    return
  endif

  let line = line[0]
  let tag = split(cur_line[-2], ' ')[-1]
  let [_, start, _] = matchstrpos(line, tag)

  call vista#source#GotoWin()
  " Move cursor to the column of tag located, otherwise the first column
  call cursor(lnum, start > -1 ? start+1 : 1)
  normal! zz

  call call('vista#util#Blink', get(g:, 'vista_blink', [2, 100]))

  if get(g:, 'vista_close_on_jump', 0)
    call vista#sidebar#Close()
  endif
endfunction

" Fold scope based on the indent.
" Jump to the target source line or source file.
function! vista#cursor#FoldOrJump() abort
  if line('.') == 1
    call vista#source#GotoWin()
    return
  endif

  " Fold or unfold when meets scope line
  if getline('.') =~ ']$'
    if foldclosed('.') != -1
      normal! zo
    else
      normal! zc
    endif
    return
  endif

  call s:Jump()
endfunction
