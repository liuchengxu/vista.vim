" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:scope_icon = ['⊕', '⊖']

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '#',
      \ 'private': '-',
      \ }

function! s:RenderLinewise() abort
  let rows = []

  " FIXME the same kind tags could be in serveral sections
  let idx = 0
  let raw_len = len(g:vista.raw)

  while idx < raw_len
    let line = g:vista.raw[idx]

    if has_key(line, 'access')
      let access = get(s:visibility_icon, line.access, '?')
    else
      let access = ''
    endif

    if !exists('s:last_kind') || has_key(line, 'kind') && s:last_kind != line.kind
      call add(rows, vista#renderer#Decorate(line.kind))
      let s:last_kind = get(line, 'kind')
      continue
    endif

    let row = vista#util#Join('  '.access, get(line, 'name'), get(line, 'signature', ''), ':'.line.line)

    call add(rows, row)

    " Inject vlnum.
    " Since we prepend the fpath and a blank line, the vlnum should plus 2.
    let line.vlnum = len(rows) + 2

    " Append a blank line in the last of a section.
    if has_key(line, 'kind') && idx < raw_len - 1
      if line.kind != get(g:vista.raw[idx+1], 'kind')
        call add(rows, '')
      endif
    endif

    let idx += 1
  endwhile

  unlet s:last_kind

  return rows
endfunction

function! vista#renderer#line#Render() abort
  if empty(g:vista.raw)
    return []
  endif

  return s:RenderLinewise()
endfunction
