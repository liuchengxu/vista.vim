" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:GetInfoFromLSPAndExtension() abort
  let raw_cur_line = getline('.')

  " TODO use range info of LSP symbols?
  if t:vista.provider ==# 'coc'
    let tag = vista#util#Trim(raw_cur_line[:stridx(raw_cur_line, ':')-1])
    return tag
  elseif t:vista.provider ==# 'markdown' || t:vista.provider ==# 'rst'
    if line('.') < 3
      return v:null
    endif
    " The first two lines are for displaying fpath. the lnum is 1-based, while
    " idex is 0-based.
    " So it's line('.') - 3 instead of line('.').
    let tag = vista#extension#{t:vista.provider}#GetHeader(line('.')-3)
    if tag is# v:null
      return v:null
    endif
    return tag
  endif

  return v:null
endfunction

function! vista#cursor#lsp#GetInfo() abort
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

  let tag = s:GetInfoFromLSPAndExtension()

  return [tag, source_line]
endfunction
