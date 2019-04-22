" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:scope_icon = ['⊕', '⊖']

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '~',
      \ 'private': '-',
      \ }

" Return the rendered row to be displayed given the depth
function! s:Assemble(line, depth) abort
  let line = a:line

  let kind = get(line, 'kind', '')

  if !empty(kind)
    let kind = vista#renderer#Decorate(kind)
  endif

  let row = vista#util#Join(
        \ repeat(' ', a:depth * 4),
        \ s:GetVisibility(line),
        \ get(line, 'name'),
        \ get(line, 'signature', ''),
        \ ' : '.kind,
        \ ':'.line.line
        \ )

  return row
endfunction

" Actually append to the rows
function! s:Append(line, rows, depth) abort
  let line = a:line
  let rows = a:rows

  let row = s:Assemble(line, a:depth)

  call add(rows, row)
  call add(s:vlnum_cache, line)
endfunction

function! s:ApplyAppend(line, row, rows) abort
  let line = a:line
  let rows = a:rows

  call add(rows, a:row)
  call add(s:vlnum_cache, line)
endfunction

function! s:Insert(container, key, line) abort
  if has_key(a:container, a:key)
    call add(a:container[a:key], a:line)
  else
    let a:container[a:key] = [a:line]
  endif
endfunction

" Return the next root name and line after appending to the rows.
function! s:AppendChild(line, rows, depth) abort
  if has_key(a:line, 'scope')
    call s:Append(a:line, a:rows, a:depth)
    let parent_name = a:line.scope
    let next_root_name = parent_name . s:scope_seperator . a:line.name
    return [next_root_name, a:line]
  endif

  return [v:null, v:null]
endfunction

function! s:Compare(s1, s2) abort
  return a:s1.line - a:s2.line
endfunction

" This way is more of heuristic.
"
" the line of child should larger than parent's, which partially fixes this issue comment:
" https://github.com/universal-ctags/ctags/issues/2065#issuecomment-485117935
"
" The previous nearest one should be the exact one.
function! s:RealParentOf(candidate) abort
  let candidate = a:candidate

  let name = candidate.scope
  let kind = candidate.scopeKind

  let parent_candidates = []
  for pc in t:vista.without_scope
    if pc.name ==# name && pc.kind ==# kind && pc.line < candidate.line
      call add(parent_candidates, pc)
    endif
  endfor

  if !empty(parent_candidates)
    call sort(parent_candidates, function('s:Compare'))
    return parent_candidates[-1]
  endif

  return v:null
endfunction

" Find all descendants of the root
function! s:DescendantsOf(candidates, root_line) abort
  let candidates = filter(copy(a:candidates),
        \ 'has_key(v:val, ''scope'')'.
        \ ' && v:val.scope =~# ''^''.a:root_line.name'.
        \ ' && v:val.scopeKind ==# a:root_line.kind'.
        \ ' && v:val.line > a:root_line.line'
        \ )

  return filter(candidates, 's:RealParentOf(v:val) ==# a:root_line')
endfunction

function! s:RenderDescendants(parent_name, parent_line, descendants, rows, depth) abort
  let depth = a:depth
  let rows = a:rows

  " Clear the previous duplicate parent line that is about to be added.
  "
  " This is a little bit stupid actually :(.
  let about_to_append = s:Assemble(a:parent_line, depth)
  let idx = 0
  while idx < len(rows)
    if rows[idx] ==# about_to_append
      unlet rows[idx]
      unlet s:vlnum_cache[idx]
    endif
    let idx += 1
  endwhile

  " Append the root actually
  call s:ApplyAppend(a:parent_line, about_to_append, rows)

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

    let descendants = s:DescendantsOf(t:vista.with_scope, child_line)

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
    call add(rows, vista#renderer#Decorate(kind))

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
  let s:scope_seperator = t:vista.source.scope_seperator()

  let rows = []

  " s:vlnum_cache is a cache for recording which original tagline
  " is related to the line in the vista sidebar, for we have to
  " remove the duplicate parents which leads to reassign the lnum
  " to the original tagline.
  let s:vlnum_cache = []

  let scope_less = {}

  " The root of hierarchy structure doesn't have scope field.
  for potential_root_line in t:vista.without_scope

    let root_name = potential_root_line.name

    let descendants = s:DescendantsOf(t:vista.with_scope, potential_root_line)

    if !empty(descendants)

      call s:RenderDescendants(root_name, potential_root_line, descendants, rows, 0)

      call add(rows, '')
      call add(s:vlnum_cache, '')

    else

      if has_key(potential_root_line, 'kind')
        call s:Insert(scope_less, potential_root_line.kind, potential_root_line)
      endif

    endif

  endfor

  call s:RenderScopeless(scope_less, rows)

  let idx = 0
  while idx < len(s:vlnum_cache)
    if !empty(s:vlnum_cache[idx])
      " idx is 0-based, while the line number is 1-based, and we prepend the
      " two lines first.
      let s:vlnum_cache[idx].vlnum = idx + 1 + 2
    endif
    let idx += 1
  endwhile

  let t:vista.vlnum_cache = s:vlnum_cache

  return rows
endfunction

function! vista#renderer#default#Render() abort
  if empty(t:vista.raw)
    return []
  endif

  return s:Render()
endfunction
