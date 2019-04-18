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
function! s:ChildrenOf(parent) abort
  let children = []
  let len = len(t:vista.with_scope)

  let idx = 0
  while idx < len
    let item = get(t:vista.with_scope, idx, {})
    if has_key(item, 'scope') && item.scope =~# '^'.a:parent
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

function! s:AppendChild(line, rows, depth) abort
  if has_key(a:line, 'scope')
    let parent = a:line.scope
    call s:Append(a:line, a:rows, a:depth)
    let me = parent.'.'.a:line.name
    return [me, a:line]
  endif
  return [v:null, v:null]
endfunction

" Find all descendants of the root
function! s:DescendantsOf(candidates, root_name) abort
  return filter(copy(a:candidates), 'has_key(v:val, ''scope'') && v:val.scope =~# ''^''.a:root_name')
endfunction

function! s:GeneralRenderDescendants(parent_name, parent_line, descendants, rows, depth) abort
  let depth = a:depth
  let rows = a:rows

  " find all the children
  let children = filter(copy(a:descendants), 'v:val.scope ==# a:parent_name')

  let grandchildren = []
  let grandchildren_line = []

  for child in children
    let [next_potentioal_root, next_potentioal_root_line] = s:AppendChild(child, rows, depth)
    if !empty(next_potentioal_root)
      call add(grandchildren, next_potentioal_root)
      call add(grandchildren_line, next_potentioal_root_line)
    endif
  endfor

  let idx = 0
  while idx < len(grandchildren)
    let child_name = grandchildren[idx]
    let child_line = grandchildren_line[idx]

    let descendants = s:DescendantsOf(t:vista.with_scope, child_name)

    if !empty(descendants)
      call s:GeneralRenderDescendants(child_name, child_line, descendants, a:rows, depth)
    endif
    let idx += 1
  endwhile
endfunction

function! s:RenderDescendants(parent_name, parent_line, descendants, rows, depth) abort
  let depth = a:depth
  let rows = a:rows

  " Append the root
  call s:Append(a:parent_line, rows, depth)
  let depth += 1

  " find all the children
  let children = filter(copy(a:descendants), 'v:val.scope ==# a:parent_name')

  let grandchildren = []
  let grandchildren_line = []

  for child in children
    let [next_potentioal_root, next_potentioal_root_line] = s:AppendChild(child, rows, depth)
    if !empty(next_potentioal_root)
      call add(grandchildren, next_potentioal_root)
      call add(grandchildren_line, next_potentioal_root_line)
    endif
  endfor

  let idx = 0
  while idx < len(grandchildren)
    let child_name = grandchildren[idx]
    let child_line = grandchildren_line[idx]

    let descendants = s:DescendantsOf(t:vista.with_scope, child_name)

    if !empty(descendants)
      " call s:GeneralRenderDescendants(child_name, child_line, descendants, a:rows, depth+1)
      call s:RenderDescendants(child_name, child_line, descendants, a:rows, depth)
    endif
    let idx += 1
  endwhile
endfunction

function! s:RenderGroupwise() abort
  let rows = []

  let scope_less = {}

  " The root of hierarchy structure doesn't have scope field.
  for potential_root_line in t:vista.without_scope
    let root_name = potential_root_line.name

    " If we get children in the way of the following, there are possibly be
    " duplicate children for the parent, e.g., implement same struct in
    " serveral sections in Rust.
    "
    " let children = filter(copy(t:vista.with_scope), 's:FilterChildren(v:val, root_name)')

    let descendants = s:DescendantsOf(t:vista.with_scope, root_name)

    if !empty(descendants)
      call s:RenderDescendants(root_name, potential_root_line, descendants, rows, 0)
      call add(rows, '')
    else
      if has_key(potential_root_line, 'kind')
        call s:Insert(scope_less, potential_root_line.kind, potential_root_line)
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
