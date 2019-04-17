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
  return has_key(a:line, 'scope') && a:line.scope =~# a:parent
endfunction

" Append row to the rows to be displayed given the depth
function! s:Append(line, rows, depth) abort
  let line = a:line
  let rows = a:rows

  let visibility = has_key(line, 'access') ? get(s:visibility_icon, line.access, '?') : ''

  let row = vista#util#Join(
        \ repeat(' ', a:depth * 4),
        \ visibility,
        \ get(line, 'name'),
        \ get(line, 'signature', ''),
        \ ': '.get(line, 'kind', ''),
        \ ' '.get(line, 'scope', ''),
        \ ':'.line.line
        \ )

  call add(rows, row)

  let line.vlnum = len(rows) + 2
endfunction

function! s:RenderHierarchyEntity(root, children, line, rows) abort
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

" Filter all the children from the whole tag list containing the scope field given the parent
function s:ChildrenOf(parent) abort
  let children = []
  let len = len(t:vista.with_scope)

  let idx = 0
  while idx < len
    let item = get(t:vista.with_scope, idx, {})
    if has_key(item, 'scope') && item.scope =~# a:parent
      call add(children, item)
      " To avoid duplicate children
      unlet t:vista.with_scope[idx]
    endif
    let idx += 1
  endwhile

  return children
endfunction

function! s:Insert(container, key, line) abort
  if has_key(a:container, a:key)
    call add(a:container[a:key], a:line)
  else
    let a:container[a:key] = [a:line]
  endif
endfunction

function! s:RenderGroupwise() abort
  let rows = []

  let scope_less = {}

  " The root of hierarchy structure doesn't have scope field.
  for line in t:vista.without_scope
    let parent = line.name

    " If we get children in the way of the following, there are possibly be
    " duplicate children for the parent, e.g., implement same struct in
    " serveral sections in Rust.
    "
    " let children = filter(copy(t:vista.with_scope), 's:FilterChildren(v:val, parent)')

    let children = s:ChildrenOf(parent)

    if !empty(children)
      call s:RenderHierarchyEntity(parent, children, line, rows)
      call add(rows, '')
    else
      if has_key(line, 'kind')
        call s:Insert(scope_less, line.kind, line)
      endif
    endif
  endfor

  for kind in keys(scope_less)
    call add(rows, kind)

    let lines = scope_less[kind]
    for line in lines
      let visibility = has_key(line, 'access') ? get(s:visibility_icon, line.access, '?') : ''

      let row = vista#util#Join(
            \ '  '.visibility,
            \ get(line, 'name'),
            \ get(line, 'signature', ''),
            \ ':'.line.line
            \ )

      call add(rows, row)

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
