" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf8

let s:has_floating_win = exists('*nvim_open_win')
let s:has_popup = exists('*popup_create')

let s:find_timer = -1
let s:cursor_timer = -1
let s:highlight_timer = -1

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
  let cur_line = split(getline('.'), ':')

  if empty(cur_line)
    return [v:null, v:null]
  endif

  let lnum = cur_line[-1]

  let source_line = t:vista.source.line_trimmed(lnum)
  if empty(source_line)
    return [v:null, v:null]
  endif

  " For scoped tag
  " Currently vlnum_cache is ctags provider only.
  if has_key(t:vista, 'vlnum_cache') && t:vista.provider ==# 'ctags'
    let tagline = t:vista.get_tagline_under_cursor()
    if !empty(tagline)
      return [tagline.name, source_line]
    endif
  endif

  function! s:RemoveVisibility(tag) abort
    if index(['+', '~', '-'], a:tag[0]) > -1
      return a:tag[1:]
    else
      return a:tag
    endif
  endfunction

  " For scopeless tag
  " peer_ilog(PEER,FORMAT,...):90
  let trimmed_line = vista#util#Trim(getline('.'))
  let left_parenthsis_idx = stridx(trimmed_line, '(')
  if left_parenthsis_idx > -1
    " Ignore the visibility symbol, e.g., +test2()
    let tag = s:RemoveVisibility(trimmed_line[0 : left_parenthsis_idx-1])
    return [tag, source_line]
  endif

  " logger_name:80
  let with_tag = split(cur_line[-2])
  if empty(with_tag)
    return [v:null, v:null]
  endif

  " Since we include the space ` `, we need to trim the result later.
  let matched = matchlist(trimmed_line, '\([a-zA-Z:#_.,<> ]\+\):\(\d\+\)$')

  let tag = get(matched, 1, '')

  if empty(tag)
    let tag = with_tag[-1]
  endif

  let tag = s:RemoveVisibility(tag)
  let tag = vista#util#Trim(tag)

  return [tag, source_line]
endfunction

function! s:EchoScope(scope) abort
  if g:vista#renderer#enable_icon
    echohl Function | echo ' '.a:scope.': ' | echohl NONE
  else
    echohl Function  | echo '['.a:scope.'] '  | echohl NONE
  endif
endfunction

" Echo the tag with detailed info in the cmdline
function! s:EchoInCmdline(msg, tag) abort
  let [msg, tag] = [a:msg, a:tag]

  " Case II:\@ $R^2 \geq Q^3$ :  paragraph:175
  try
    let [_, start, end] = matchstrpos(msg, '\C'.tag)

    " If couldn't find the tag in the msg
    if start == -1
      echohl Function | echo msg | echohl NONE
      return
    endif

  catch /^Vim\%((\a\+)\)\=:E869/

    echohl Function | echo msg | echohl NONE
    return

  endtry

  let echoed_scope = v:false

  if has_key(t:vista, 'vlnum_cache')
    " should exclude the first two lines and keep in mind that the 1-based and
    " 0-based.
    " This is really error prone.
    let tagline = get(t:vista.vlnum_cache, line('.') - 3, '')
    if !empty(tagline)
      if has_key(tagline, 'scope')
        call s:EchoScope(tagline.scope)
      else
        call s:EchoScope(tagline.kind)
      endif
      let echoed_scope = v:true
    endif
  endif

  " Try highlighting the scope of current tag
  if !echoed_scope
    let linenr = vista#util#LowerIndentLineNr()

    " Echo the scope of current tag if found
    if linenr != 0
      let scope = matchstr(getline(linenr), '\a\+$')
      if !empty(scope)
        call s:EchoScope(scope)
      else
        " For the kind renderer
        let pieces = split(getline(linenr), ' ')
        if len(pieces) > 1
          let scope = pieces[1]
          call s:EchoScope(scope)
        endif
      endif
    endif
  endif

  " if start is 0, msg[0:-1] will display the redundant whole msg.
  if start != 0
    echohl Statement | echon msg[0 : start-1] | echohl NONE
  endif

  echohl Search    | echon msg[start : end-1] | echohl NONE
  echohl Statement | echon msg[end : ]        | echohl NONE
endfunction

function! s:DisplayInFloatingWin(...) abort
  if s:has_popup
    call call('vista#popup#Display', a:000)
  elseif s:has_floating_win
    call call('vista#floating#Display', a:000)
  else
    call vista#error#Need('neovim compiled with floating window support or vim compiled with popup feature')
  endif
endfunction

function! s:RevealInSourceFile(lnum, tag) abort
  noautocmd execute t:vista.source.winnr().'wincmd w'

  silent execute 'normal!' a:lnum.'z.'

  let [_, start, end] = matchstrpos(getline('.'), a:tag)

  call vista#util#Blink(1, 100, [a:lnum, start+1, strlen(a:tag)])

  noautocmd wincmd p
endfunction

" Show the detail of current tag/symbol under cursor.
function! s:ShowDetail() abort
  let [tag, source_line] = s:GetInfoUnderCursor()
  let s:cur_tag = tag

  if empty(tag) || empty(source_line)
    echo "\r"
    return
  endif

  let opts = ['echo', 'floating_win', 'scroll', 'both']
  let strategy = get(g:, 'vista_echo_cursor_strategy', 'echo')

  let msg = vista#util#Truncate(source_line)
  let lnum = s:GetTrailingLnum()

  if strategy == opts[0]
    call s:EchoInCmdline(msg, tag)
  elseif strategy == opts[1]
    call s:DisplayInFloatingWin(lnum, tag)
  elseif strategy == opts[2]
    call s:RevealInSourceFile(lnum, tag)
  elseif strategy == opts[3]
    call s:EchoInCmdline(msg, tag)
    if s:has_floating_win
      call s:DisplayInFloatingWin(lnum, tag)
    else
      call s:RevealInSourceFile(lnum, tag)
    endif
  else
    call vista#error#InvalidOption('g:vista_echo_cursor_strategy', opts)
  endif

  call s:ApplyHighlight(line('.'), v:false, tag)
endfunction

function! s:Compare(s1, s2) abort
  return a:s1.lnum - a:s2.lnum
endfunction

function! s:FindNearestMethodOrFunction(_timer) abort
  if !exists('t:vista') || !has_key(t:vista, 'functions') || !has_key(t:vista, 'source')
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
    let [_, start, _] = matchstrpos(cur_line, '[a-zA-Z0-9_#:]')

    " If we know the tag, then what we have to do is to use the length of tag
    " based on the starting point.
    "
    " start is 0-based, while the column used in matchstrpos is 1-based.
    if a:0 == 1
      let hi_pos = [a:lnum, start+1, strlen(a:1)]
    else
      let [matched, end, _] = matchstrpos(cur_line, ':\d\+$')
      let hi_pos = [a:lnum, start+1, end-len(matched)]
    endif
  endif

  let w:vista_highlight_id = matchaddpos('IncSearch', [hi_pos])

  if a:ensure_visible
    execute 'normal!' a:lnum.'z.'
  endif
endfunction

function! s:HighlightNearestTag(_timer) abort
  let winnr = t:vista.winnr()
  if winnr == -1
        \ || vista#ShouldSkip()
        \ || !s:HasVlnum()
        \ || mode() !=# 'n'
    return
  endif

  let s:vlnum = vista#util#BinarySearch(t:vista.raw, line('.'), 'line', 'vlnum')

  if empty(s:vlnum)
    return
  endif

  " Skip if the vlnum is same with previous one
  if s:vlnum is v:null || s:last_vlnum == s:vlnum
    return
  endif

  let s:last_vlnum = s:vlnum

  let winnr = t:vista.winnr()
  " noautocmd is necessary, otherwise it may interfere the echoed message by
  " other plugins, e.g., the warning/error message from ALE.
  if winnr() != winnr
    noautocmd execute winnr.'wincmd w'
    let l:switch_back = 1
  endif

  call s:ApplyHighlight(s:vlnum, v:true)

  if exists('l:switch_back')
    noautocmd wincmd p
  endif
endfunction

" Fold scope based on the indent.
" Jump to the target source line or source file.
function! vista#cursor#FoldOrJump() abort
  if line('.') == 1
    call vista#source#GotoWin()
    return
  endif

  " Fold or unfold when meets the top level tag line
  if indent('.') == 0
    if !empty(getline('.'))
      if foldclosed('.') != -1
        normal! zo
      else
        normal! zc
      endif
    endif
    return
  endif

  call vista#jump#TagLine(get(s:, 'cur_tag', ''))
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

  let delay = get(g:, 'vista_find_nearest_method_or_function_delay', 300)
  let s:find_timer = timer_start(
        \ delay,
        \ function('s:FindNearestMethodOrFunction'),
        \ )
endfunction

function! vista#cursor#NearestSymbol() abort
  return vista#util#BinarySearch(t:vista.raw, line('.'), 'line', 'name')
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
    let cnt = matchstr(splitted[-1], '\d\+')
    call s:EchoScope(scope)
    echohl Keyword | echon cnt | echohl NONE
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

" This happens on calling `:Vista show` but the vista window is still invisible.
function! vista#cursor#ShowTagFor(lnum) abort
  if !s:HasVlnum()
    return
  endif

  let s:vlnum = vista#util#BinarySearch(t:vista.raw, a:lnum, 'line', 'vlnum')
  if empty(s:vlnum)
    return
  endif

  call s:ApplyHighlight(s:vlnum, v:true)
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
    call vista#floating#Close()
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
