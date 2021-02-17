" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:GetInfoFromLSPAndExtension() abort
  let raw_cur_line = getline('.')

  " TODO use range info of LSP symbols?
  if g:vista.provider ==# 'coc'
    if !has_key(g:vista, 'vlnum2tagname')
      return v:null
    endif
    if has_key(g:vista.vlnum2tagname, line('.'))
      return g:vista.vlnum2tagname[line('.')]
    else
      let items = split(raw_cur_line)
      if g:vista#renderer#enable_icon
        return join(items[1:-2], ' ')
      else
        return join(items[:-2], ' ')
      endif
    endif
  elseif g:vista.provider ==# 'nvim_lsp'
    return substitute(raw_cur_line, '\v.*\s(.*):.*', '\1', '')
  elseif g:vista.provider ==# 'markdown' || g:vista.provider ==# 'rst'
    if line('.') < 3
      return v:null
    endif
    " The first two lines are for displaying fpath. the lnum is 1-based, while
    " idex is 0-based.
    " So it's line('.') - 3 instead of line('.').
    let tag = vista#extension#{g:vista.provider}#GetHeader(line('.')-3)
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

  let source_line = g:vista.source.line_trimmed(lnum)
  if empty(source_line)
    return [v:null, v:null]
  endif

  let tag = s:GetInfoFromLSPAndExtension()

  return [tag, source_line]
endfunction
