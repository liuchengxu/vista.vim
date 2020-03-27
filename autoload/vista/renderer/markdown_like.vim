" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

function! s:Join(line, icon) abort
  let line = a:line

  let text = line.text
  let lnum = line.lnum
  let level = line.level
  let row = repeat(' ', 2 * (level - 1)).a:icon.text.' H'.level.':'.lnum

  return row
endfunction

function! s:BuildRow(idx, line) abort
  if a:idx+1 == len(s:data) || s:data[a:idx+1].level != a:line.level
    return s:Join(a:line, g:vista_icon_indent[0])
  else
    return s:Join(a:line, g:vista_icon_indent[1])
  endif
endfunction

" Given the metadata of headers of markdown, return the rendered lines to display.
"
" line.lnum is 1-based.
"
" The metadata of markdown headers is a List of Dict:
" {'lnum': 1, 'level': '4', 'text': 'Vista.vim'}
function! s:MD(idx, line) abort
  return s:BuildRow(a:idx, a:line)
endfunction

" The metadata of rst headers is a List of Dict:
" {'lnum': 1, 'level': '4', 'text': 'Vista.vim'}
function! s:RST(idx, line) abort
  return s:BuildRow(a:idx, a:line)
endfunction

" markdown
function! vista#renderer#markdown_like#MD(data) abort
  let s:data = a:data
  return map(a:data, 's:MD(v:key, v:val)')
endfunction

" restructuredText
function! vista#renderer#markdown_like#RST(data) abort
  let s:data = a:data
  return map(a:data, 's:RST(v:key, v:val)')
endfunction
