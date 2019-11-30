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

function! s:RemoveVisibility(tag) abort
  if index(['+', '~', '-'], a:tag[0]) > -1
    return a:tag[1:]
  else
    return a:tag
  endif
endfunction

function! s:GetLSPInfo() abort
endfunction

" Try matching the exact tag given the trimmed line in the vista window.
function! s:MatchTag(trimmed_line) abort
  " Since we include the space ` `, we need to trim the result later.
  " / --> github.com/golang/dep/gps:11
  if t:vista.provider ==# 'markdown'
    let matched = matchlist(a:trimmed_line, '\([a-zA-Z:#_.,/<> ]\-\+\)\(H\d:\d\+\)$')
  else
    let matched = matchlist(a:trimmed_line, '\([a-zA-Z:#_.,/<> ]\-\+\):\(\d\+\)$')
  endif

  return get(matched, 1, '')
endfunction

" Get tag and corresponding source line at current cursor position.
"
" Return: [tag, source_line]
function! s:GetInfoUnderCursor() abort
  let raw_cur_line = getline('.')

  if empty(raw_cur_line)
    return [v:null, v:null]
  endif

  " tag like s:StopCursorTimer has `:`, so we can't simply use split(tag, ':')
  let last_semicoln_idx = strridx(raw_cur_line, ':')
  let lnum = raw_cur_line[last_semicoln_idx+1:]

  let source_line = t:vista.source.line_trimmed(lnum)
  if empty(source_line)
    return [v:null, v:null]
  endif

  " TODO use range info of LSP symbols?
  if t:vista.provider ==# 'coc'
    let tag = vista#util#Trim(raw_cur_line[:stridx(raw_cur_line, ':')-1])
    return [tag, source_line]
  elseif t:vista.provider ==# 'markdown' || t:vista.provider ==# 'rst'
    if line('.') < 3
      return [v:null, v:null]
    endif
    " The first two lines are for displaying fpath. the lnum is 1-based, while
    " idex is 0-based.
    " So it's line('.') - 3 instead of line('.').
    let tag = vista#extension#{t:vista.provider}#GetHeader(line('.')-3)
    if tag is# v:null
      return [v:null, v:null]
    endif
    return [tag, source_line]
  endif

  " For scoped tag
  " Currently vlnum_cache is ctags provider only.
  if has_key(t:vista, 'vlnum_cache') && t:vista.provider ==# 'ctags'
    let tagline = t:vista.get_tagline_under_cursor()
    if !empty(tagline)
      return [tagline.name, source_line]
    endif
  endif

  " For scopeless tag
  " peer_ilog(PEER,FORMAT,...):90
  let trimmed_line = vista#util#Trim(raw_cur_line)
  let left_parenthsis_idx = stridx(trimmed_line, '(')
  if left_parenthsis_idx > -1
    " Ignore the visibility symbol, e.g., +test2()
    let tag = s:RemoveVisibility(trimmed_line[0 : left_parenthsis_idx-1])
    return [tag, source_line]
  endif

  let tag = s:MatchTag(trimmed_line)
  if empty(tag)
    let tag = raw_cur_line[:last_semicoln_idx-1]
  endif

  let tag = s:RemoveVisibility(vista#util#Trim(tag))

  return [tag, source_line]
endfunction

function! s:EchoScope(scope) abort
  if g:vista#renderer#enable_icon
    echohl Function | echo ' '.a:scope.': ' | echohl NONE
  else
    echohl Function  | echo '['.a:scope.'] '  | echohl NONE
  endif
endfunction

function! s:EchoScopeFromCacheIsOk() abort
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
      return v:true
    endif
  endif
  return v:false
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

  " Try highlighting the scope of current tag
  if !s:EchoScopeFromCacheIsOk()
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
    call call('vista#popup#DisplayAt', a:000)
  elseif s:has_floating_win
    call call('vista#floating#DisplayAt', a:000)
  else
    call vista#error#Need('neovim compiled with floating window support or vim compiled with popup feature')
  endif
endfunction

function! s:ApplyPeek(lnum, tag) abort
  silent execute 'normal!' a:lnum.'z.'
  let [_, start, _] = matchstrpos(getline('.'), a:tag)
  call vista#util#Blink(1, 100, [a:lnum, start+1, strlen(a:tag)])
endfunction

if exists('*win_execute')
  function! s:PeekInSourceFile(lnum, tag) abort
    call win_execute(bufwinid(t:vista.source.bufnr), 'noautocmd call s:ApplyPeek(a:lnum, a:tag)')
  endfunction
else
  function! s:PeekInSourceFile(lnum, tag) abort
    call vista#WinExecute(t:vista.source.winnr(), function('s:ApplyPeek'), a:lnum, a:tag)
  endfunction
endif

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
    call s:EchoInCmdline(msg, tag)
  elseif strategy ==# s:echo_cursor_opts[1]
    call s:DisplayInFloatingWin(lnum, tag)
  elseif strategy ==# s:echo_cursor_opts[2]
    call s:PeekInSourceFile(lnum, tag)
  elseif strategy ==# s:echo_cursor_opts[3]
    call s:EchoInCmdline(msg, tag)
    if s:has_floating_win
      call s:DisplayInFloatingWin(lnum, tag)
    else
      call s:PeekInSourceFile(lnum, tag)
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

function! s:TryFoldIsOk() abort
  if indent('.') == 0
    if !empty(getline('.'))
      if foldclosed('.') != -1
        normal! zo
      elseif foldlevel('.') != 0
        normal! zc
      endif
    endif
    return v:true
  else
    return v:false
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
  if s:TryFoldIsOk()
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

function! s:ShowFoldedDetail() abort
  let foldclosed_end = foldclosedend('.')
  let curlnum = line('.')
  let lines = getbufline(t:vista.bufnr, curlnum, foldclosed_end)

  if s:has_floating_win
    call vista#floating#DisplayRawAt(curlnum, lines)
  elseif s:has_popup
    call vista#popup#DisplayRawAt(curlnum, lines)
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
    let cnt = matchstr(splitted[-1], '\d\+')
    call s:EchoScope(scope)
    echohl Keyword | echon cnt | echohl NONE
    return
  endif

  if foldclosed('.') != -1
    if !s:has_floating_win && !s:has_popup
      return
    endif
    call s:ShowFoldedDetail()
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
