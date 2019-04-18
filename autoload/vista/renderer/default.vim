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

" Return the row to be displayed in the vista sidebar given the depth
function! s:Assemble(line, depth) abort
  let line = a:line

  let row = vista#util#Join(
        \ repeat(' ', a:depth * 4),
        \ s:GetVisibility(line),
        \ get(line, 'name'),
        \ get(line, 'signature', ''),
        \ ': '.get(line, 'kind', ''),
        \ ' '.get(line, 'scope', ''),
        \ ':'.line.line
        \ )

  return row
endfunction

" Append row to the rows to be displayed given the depth
function! s:Append(line, rows, depth) abort
  let line = a:line
  let rows = a:rows

  let row = s:Assemble(line, a:depth)

  call add(rows, row)

  let line.vlnum = len(rows) + 2
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

function! s:RenderDescendants(parent_name, parent_line, descendants, rows, depth) abort
  let depth = a:depth
  let rows = a:rows

  " Clear the previous duplicate parent line that is about to be added.
  "
  " This is a little bit stupid actually :(.
  let appended = s:Assemble(a:parent_line, depth)
  let idx = 0
  while idx < len(rows)
    if rows[idx] ==# appended
      unlet rows[idx]
    endif
    let idx += 1
  endwhile

  " Append the root actually
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
      call s:RenderDescendants(child_name, child_line, descendants, a:rows, depth)
    endif

    let idx += 1
  endwhile
endfunction

function! s:GetVisibility(line) abort
  return has_key(a:line, 'access') ? get(s:visibility_icon, a:line.access, '?') : ''
endfunction

function! s:RenderScopeless(scope_less, rows) abort
  let rows = a:rows
  let scope_less = a:scope_less

  for kind in keys(scope_less)
    call add(rows, kind)

    let lines = scope_less[kind]
    for line in lines
      let row = vista#util#Join(
            \ '  '.s:GetVisibility(line),
            \ get(line, 'name'),
            \ get(line, 'signature', ''),
            \ ':'.line.line
            \ )

      call add(rows, row)

      let line.vlnum = len(rows) + 2
    endfor

    call add(rows, '')
  endfor
endfunction

function! s:Render() abort
  let rows = []

  let scope_less = {}

  " The root of hierarchy structure doesn't have scope field.
  for potential_root_line in t:vista.without_scope
    let root_name = potential_root_line.name

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

  call s:RenderScopeless(scope_less, rows)

  return rows
endfunction

function! vista#renderer#default#Render() abort
  if empty(t:vista.raw)
    return []
  endif

  return s:Render()
endfunction
