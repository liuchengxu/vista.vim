" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:scope_icon = ['⊕', '⊖']

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '~',
      \ 'private': '-',
      \ }

function! s:FilterChildren(line, parent) abort
  if has_key(a:line, 'scope') && a:line.scope =~# '^'.a:parent
    return 1
  else
    return 0
  endif
endfunction

" Append row to the rows to be displayed given the depth
function! s:Append(line, rows, depth) abort
  let line = a:line
  let rows = a:rows

  if has_key(line, 'access')
    let access = get(s:visibility_icon, line.access, '?')
  else
    let access = ''
  endif

  let row = vista#util#Join(
        \ repeat(' ', a:depth*4),
        \ access,
        \ get(line, 'name'),
        \ get(line, 'signature', ''),
        \ ': '.get(line, 'kind', ''),
        \ ':'.line.line
        \ )

  call add(rows, row)

  " Inject vlnum.
  " Since we prepend the fpath and a blank line, the vlnum should plus 2.
  let line.vlnum = len(rows) + 2
endfunction

function! s:RenderScope(root, children, line, rows) abort
  let parent = a:root
  let line = a:line
  let rows = a:rows

  let depth = 0
  call s:Append(line, rows, depth)

  let depth += 1

  for child in a:children
    if child.scope ==# parent
      call s:Append(child, rows, depth)
    else
      let depth += 1
      call s:Append(child, rows, depth)
      let parent = child.scope
    endif
  endfor
endfunction

function! s:RenderGroupwise() abort
  let rows = []

  let scope_less = {}

  " The root of hierarchy structure doesn't have scope field.
  for line in t:vista.without_scope
    let parent = line.name
    let children = filter(copy(t:vista.with_scope), 's:FilterChildren(v:val, parent)')

    if !empty(children)
      call s:RenderScope(parent, children, line, rows)
      call add(rows, '')
    else
      if has_key(line, 'kind')
        if has_key(scope_less, line.kind)
          call add(scope_less[line.kind], line)
        else
          let scope_less[line.kind] = [line]
        endif
      endif
    endif
  endfor

  for kind in keys(scope_less)
    call add(rows, kind)
    let lines = scope_less[kind]
    for line in lines
      if has_key(line, 'access')
        let access = get(s:visibility_icon, line.access, '?')
      else
        let access = ''
      endif

      let row = vista#util#Join(
            \ '  '.access,
            \ get(line, 'name'),
            \ get(line, 'signature', ''),
            \ ':'.line.line
            \ )

      call add(rows, row)

      " Inject vlnum.
      " Since we prepend the fpath and a blank line, the vlnum should plus 2.
      let line.vlnum = len(rows) + 2
    endfor
    call add(rows, '')
  endfor

  return rows
endfunction

function! vista#renderer#default#Render() abort
  if empty(t:vista.raw)
    return []
  endif

  return s:RenderGroupwise()
endfunction
