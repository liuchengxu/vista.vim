" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Try matching the exact tag given the trimmed line in the vista window.
function! s:MatchTag(trimmed_line) abort
  " Since we include the space ` `, we need to trim the result later.
  " / --> github.com/golang/dep/gps:11
  if g:vista.provider ==# 'markdown'
    let matched = matchlist(a:trimmed_line, '\([a-zA-Z:#_.,/<> ]\-\+\)\(H\d:\d\+\)$')
  else
    let matched = matchlist(a:trimmed_line, '\([a-zA-Z:#_.,/<> ]\-\+\):\(\d\+\)$')
  endif

  return get(matched, 1, '')
endfunction

function! s:RemoveVisibility(tag) abort
  if index(['+', '~', '-'], a:tag[0]) > -1
    return a:tag[1:]
  else
    return a:tag
  endif
endfunction

function! vista#cursor#ctags#GetInfo() abort
  let raw_cur_line = getline('.')

  if empty(raw_cur_line)
    return [v:null, v:null]
  endif

  " tag like s:StopCursorTimer has `:`, so we can't simply use split(tag, ':')
  let last_semicoln_idx = strridx(raw_cur_line, ':')
  let lnum = raw_cur_line[last_semicoln_idx+1:]

  let source_line = g:vista.source.line_trimmed(lnum)
  if empty(source_line)
    return [v:null, v:null]
  endif

  " For scoped tag
  " Currently vlnum_cache is ctags provider only.
  if has_key(g:vista, 'vlnum_cache') && g:vista.provider ==# 'ctags'
    let tagline = g:vista.get_tagline_under_cursor()
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
