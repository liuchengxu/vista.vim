" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf8

let s:has_floating_win = exists('*nvim_open_win')
let s:has_popup = exists('*popup_create')

let s:find_timer = -1
let s:cursor_timer = -1
let s:highlight_timer = -1

let s:find_delay = get(g:, 'vista_find_nearest_method_or_function_delay', 300)
let s:cursor_delay = get(g:, 'vista_cursor_delay', 400)

let s:echo_cursor_opts = ['echo', 'floating_win', 'scroll', 'both']

let s:last_vlnum = v:null

function! s:GenericStopTimer(timer) abort
  execute 'if '.a:timer.' != -1 |'.
        \ '  call timer_stop('.a:timer.') |'.
        \ '  let 'a:timer.' = -1 |'.
        \ 'endif'
endfunction

function! s:StopFindTimer() abort
  call s:GenericStopTimer('s:find_timer')
endfunction

function! s:StopCursorTimer() abort
  call s:GenericStopTimer('s:cursor_timer')
endfunction

function! s:StopHighlightTimer() abort
  call s:GenericStopTimer('s:highlight_timer')
endfunction

" Get tag and corresponding source line at current cursor position.
"
" Return: [tag, source_line]
function! s:GetInfoUnderCursor() abort
  if t:vista.provider ==# 'ctags'
    return vista#cursor#ctags#GetInfo()
  else
    return vista#cursor#lsp#GetInfo()
  endif
endfunction

function! s:DisplayInFloatingWin(...) abort
  if s:has_popup
    call call('vista#popup#DisplayAt', a:000)
  elseif s:has_floating_win
    call call('vista#floating#DisplayAt', a:000)
  else
    call vista#error#Need('neovim compiled with floating window support or vim compiled with popup feature')
  endif
endfunction

" Show the detail of current tag/symbol under cursor.
function! s:ShowDetail() abort
  let [tag, source_line] = s:GetInfoUnderCursor()

  if empty(tag) || empty(source_line)
    echo "\r"
    return
  endif

  let strategy = get(g:, 'vista_echo_cursor_strategy', 'echo')

  let msg = vista#util#Truncate(source_line)
  let lnum = s:GetTrailingLnum()

  if strategy ==# s:echo_cursor_opts[0]
    call vista#echo#EchoInCmdline(msg, tag)
  elseif strategy ==# s:echo_cursor_opts[1]
    call s:DisplayInFloatingWin(lnum, tag)
  elseif strategy ==# s:echo_cursor_opts[2]
    call vista#source#PeekSymbol(lnum, tag)
  elseif strategy ==# s:echo_cursor_opts[3]
    call vista#echo#EchoInCmdline(msg, tag)
    if s:has_floating_win
      call s:DisplayInFloatingWin(lnum, tag)
    else
      call vista#source#PeekSymbol(lnum, tag)
    endif
  else
    call vista#error#InvalidOption('g:vista_echo_cursor_strategy', s:echo_cursor_opts)
  endif

  call s:ApplyHighlight(line('.'), v:false, tag)
endfunction

function! s:Compare(s1, s2) abort
  return a:s1.lnum - a:s2.lnum
endfunction

function! s:FindNearestMethodOrFunction(_timer) abort
  if !exists('t:vista')
        \ || !has_key(t:vista, 'functions')
        \ || !has_key(t:vista, 'source')
    return
  endif
  call sort(t:vista.functions, function('s:Compare'))
  let result = vista#util#BinarySearch(t:vista.functions, line('.'), 'lnum', 'text')
  if empty(result)
    let result = ''
  endif
  call setbufvar(t:vista.source.bufnr, 'vista_nearest_method_or_function', result)

  call s:StopHighlightTimer()

  if vista#sidebar#IsVisible()
    let s:highlight_timer = timer_start(200, function('s:HighlightNearestTag'))
  endif
endfunction

function! s:HasVlnum() abort
  return exists('t:vista')
        \ && has_key(t:vista, 'raw')
        \ && !empty(t:vista.raw)
        \ && has_key(t:vista.raw[0], 'vlnum')
endfunction

" Highlight the line given the line number and ensure it's visible if required.
"
" lnum - current line number in vista window
" ensure_visible - kepp this line visible
" optional: tag - accurate tag
function! s:ApplyHighlight(lnum, ensure_visible, ...) abort
  if exists('w:vista_highlight_id')
    call matchdelete(w:vista_highlight_id)
    unlet w:vista_highlight_id
  endif

  if get(g:, 'vista_highlight_whole_line', 0)
    let hi_pos = a:lnum
  else
    let cur_line = getline(a:lnum)
    " Current line may contains +,-,~, use `\S` is incorrect to find the right
    " starting postion.
    let [_, start, _] = matchstrpos(cur_line, '[a-zA-Z0-9_,#:]')

    " If we know the tag, then what we have to do is to use the length of tag
    " based on the starting point.
    "
    " start is 0-based, while the column used in matchstrpos is 1-based.
    if a:0 == 1
      let hi_pos = [a:lnum, start+1, strlen(a:1)]
    else
      let [_, end, _] = matchstrpos(cur_line, ':\d\+$')
      let hi_pos = [a:lnum, start+1, end - start]
    endif
  endif

  let w:vista_highlight_id = matchaddpos('IncSearch', [hi_pos])

  if a:ensure_visible
    execute 'normal!' a:lnum.'z.'
  endif
endfunction

" Highlight the nearest tag in the vista window.
function! s:HighlightNearestTag(_timer) abort
  if !exists('t:vista')
    return
  endif
  let winnr = t:vista.winnr()

  if winnr == -1
        \ || vista#ShouldSkip()
        \ || !s:HasVlnum()
        \ || mode() !=# 'n'
    return
  endif

  let found = vista#util#BinarySearch(t:vista.raw, line('.'), 'line', '')
  if empty(found)
    return
  endif

  let s:vlnum = get(found, 'vlnum', v:null)
  " Skip if the vlnum is same with previous one
  if empty(s:vlnum) || s:last_vlnum == s:vlnum
    return
  endif

  let s:last_vlnum = s:vlnum

  let tag = get(found, 'name', v:null)
  if !empty(tag)
    call vista#WinExecute(winnr, function('s:ApplyHighlight'), s:vlnum, v:true, tag)
  else
    call vista#WinExecute(winnr, function('s:ApplyHighlight'), s:vlnum, v:true)
  endif
endfunction

" Fold or unfold when meets the top level tag line
function! s:TryFoldIsOk() abort
  if indent('.') == 0
    if !empty(getline('.'))
      if foldclosed('.') != -1
        normal! zo
        return v:true
      elseif foldlevel('.') != 0
        normal! zc
        return v:true
      endif
    endif
  endif
  return v:false
endfunction

" Fold scope based on the indent.
" Jump to the target source line or source file.
function! vista#cursor#FoldOrJump() abort
  if line('.') == 1
    call vista#source#GotoWin()
    return
  elseif s:TryFoldIsOk()
    return
  endif

  let tag_under_cursor = s:GetInfoUnderCursor()[0]
  call vista#jump#TagLine(tag_under_cursor)
endfunction

" This happens when you are in the window of source file
function! vista#cursor#FindNearestMethodOrFunction() abort
  if !exists('t:vista')
        \ || !has_key(t:vista, 'functions')
        \ || bufnr('') != t:vista.source.bufnr
    return
  endif

  call s:StopFindTimer()

  if empty(t:vista.functions)
    call setbufvar(t:vista.source.bufnr, 'vista_nearest_method_or_function', '')
    return
  endif

  let s:find_timer = timer_start(
        \ s:find_delay,
        \ function('s:FindNearestMethodOrFunction'),
        \ )
endfunction

function! vista#cursor#NearestSymbol() abort
  return vista#util#BinarySearch(t:vista.raw, line('.'), 'line', 'name')
endfunction

" Show the folded content if in a closed fold.
function! s:ShowFoldedDetailIsOk() abort
  if foldclosed('.') != -1
    if s:has_floating_win || s:has_popup
      let foldclosed_end = foldclosedend('.')
      let curlnum = line('.')
      let lines = getbufline(t:vista.bufnr, curlnum, foldclosed_end)

      if s:has_floating_win
        call vista#floating#DisplayRawAt(curlnum, lines)
      elseif s:has_popup
        call vista#popup#DisplayRawAt(curlnum, lines)
      endif

      return v:true
    endif
  endif
  return v:false
endfunction

function! vista#cursor#ShowDetail(_timer) abort
  if empty(getline('.'))
        \ || vista#echo#EchoScopeInCmdlineIsOk()
        \ || s:ShowFoldedDetailIsOk()
    return
  endif

  call s:ShowDetail()
endfunction

function! vista#cursor#ShowDetailWithDelay() abort
  call s:StopCursorTimer()

  let s:cursor_timer = timer_start(
        \ s:cursor_delay,
        \ function('vista#cursor#ShowDetail'),
        \ )
endfunction

" This happens on calling `:Vista show` but the vista window is still invisible.
function! vista#cursor#ShowTagFor(lnum) abort
  if !s:HasVlnum()
    return
  endif

  let found = vista#util#BinarySearch(t:vista.raw, a:lnum, 'line', '')
  if empty(found)
    return
  endif
  let s:vlnum = get(found, 'vlnum', v:null)
  if empty(s:vlnum)
    return
  endif

  let tag = get(found, 'name', v:null)
  if !empty(tag)
    call s:ApplyHighlight(s:vlnum, v:true, tag)
  else
    call s:ApplyHighlight(s:vlnum, v:true)
  endif
endfunction

function! vista#cursor#ShowTag() abort
  if !s:HasVlnum()
    return
  endif

  let s:vlnum = vista#util#BinarySearch(t:vista.raw, line('.'), 'line', 'vlnum')

  if empty(s:vlnum)
    return
  endif

  let winnr = t:vista.winnr()

  if winnr() != winnr
    execute winnr.'wincmd w'
  endif

  call cursor(s:vlnum, 1)
  normal! zz
endfunction

" Extract the line number from last section of cursor line in the vista window
function! s:GetTrailingLnum() abort
  return str2nr(matchstr(getline('.'), '\d\+$'))
endfunction

function! vista#cursor#TogglePreview() abort
  if get(t:vista, 'floating_visible', v:false)
        \ || get(t:vista, 'popup_visible', v:false)
    call vista#GenericCloseOverlay()
    return
  endif

  let [tag, source_line] = s:GetInfoUnderCursor()

  if empty(tag) || empty(source_line)
    echo "\r"
    return
  endif

  let lnum = s:GetTrailingLnum()

  call s:DisplayInFloatingWin(lnum, tag)
endfunction
