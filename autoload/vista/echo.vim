" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf8

function! s:EchoScope(scope) abort
  if g:vista#renderer#enable_icon
    echohl Function | echo ' '.a:scope.': ' | echohl NONE
  else
    echohl Function  | echo '['.a:scope.'] '  | echohl NONE
  endif
endfunction

function! s:TryParseAndEchoScope() abort
  let linenr = vista#util#LowerIndentLineNr()

  " Echo the scope of current tag if found
  if linenr != 0
    let scope = matchstr(getline(linenr), '\a\+$')
    if !empty(scope)
      call s:EchoScope(scope)
    else
      " For the kind renderer
      let pieces = split(getline(linenr), ' ')
      if !empty(pieces)
        let scope = pieces[1]
        call s:EchoScope(scope)
      endif
    endif
  endif
endfunction

function! vista#echo#EchoScopeInCmdlineIsOk() abort
  let cur_line = getline('.')
  if cur_line[-1:] ==# ']'
    let splitted = split(cur_line)
    " Join the scope parts in case of they contains spaces, e.g., structure names
    let scope = join(splitted[1:-2], ' ')
    let cnt = matchstr(splitted[-1], '\d\+')
    call s:EchoScope(scope)
    echohl Keyword | echon cnt | echohl NONE
    return v:true
  endif
  return v:false
endfunction

function! s:EchoScopeFromCacheIsOk() abort
  if has_key(g:vista, 'vlnum_cache')
    " should exclude the first two lines and keep in mind that the 1-based and
    " 0-based.
    " This is really error prone.
    let tagline = get(g:vista.vlnum_cache, line('.') - 3, '')
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
" Try to echo the scope and then the tag.
function! vista#echo#EchoInCmdline(msg, tag) abort
  let [msg, tag] = [a:msg, a:tag]

  " Case II:\@ $R^2 \geq Q^3$ :  paragraph:175
  try
    let start = stridx(msg, tag)

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
    call s:TryParseAndEchoScope()
  endif

  " if start is 0, msg[0:-1] will display the redundant whole msg.
  if start != 0
    echohl Statement | echon msg[0 : start-1] | echohl NONE
  endif

  let end = start + strlen(tag)
  echohl Search    | echon msg[start : end-1] | echohl NONE
  echohl Statement | echon msg[end : ]        | echohl NONE
endfunction
