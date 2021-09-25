" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

let s:scope_icon = ['⊕', '⊖']

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '~',
      \ 'private': '-',
      \ }

let g:vista#renderer#default#vlnum_offset = 3

let s:indent_size = g:vista#renderer#enable_icon ? 2 : 4

" Return the rendered row to be displayed given the depth
function! s:Assemble(line, depth) abort
  let line = a:line

  let kind = get(line, 'kind', '')
  let kind_icon = vista#renderer#IconFor(kind)
  let kind_icon = empty(kind_icon) ? '' : kind_icon.' '
  let kind_text = vista#renderer#KindFor(kind)
  let kind_text = empty(kind_text) ? '' : ' '.kind_text

  let row = vista#util#Join(
        \ repeat(' ', a:depth * s:indent_size),
        \ s:GetVisibility(line),
        \ kind_icon,
        \ get(line, 'name'),
        \ get(line, 'signature', ''),
        \ kind_text,
        \ ':'.get(line, 'line', '')
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
  for pc in g:vista.without_scope
    if pc.name ==# name && pc.kind ==# kind && pc.line <= candidate.line
      call add(parent_candidates, pc)
    endif
  endfor

  if !empty(parent_candidates)
    call sort(parent_candidates, function('s:Compare'))
    return parent_candidates[-1]
  endif

  return {}
endfunction

" Previously we use the regexp to see if the scope of candidate is matched:
"
" \ ' && v:val.scope =~# ''^''.l:scope'.
"
" but it runs into the error like NFA E869 '\@ ' in some cases, so we use this
" now. Ref #161
function! s:StartWith(candidate_scope, root_scope) abort
  return a:candidate_scope[:len(a:root_scope)] == a:root_scope
endfunction

" Find all descendants of the root
function! s:DescendantsOf(candidates, root_line, scope) abort
  let candidates = filter(copy(a:candidates),
        \ 'has_key(v:val, ''scope'')'.
        \ ' && s:StartWith(v:val.scope, a:scope)'.
        \ ' && v:val.scopeKind ==# a:root_line.kind'.
        \ ' && v:val.line >= a:root_line.line'
        \ )

  return candidates
  " The real parent problem seemingly has been solved?
  " return filter(candidates, 's:RealParentOf(v:val) ==# a:root_line')
endfunction

function! s:DescendantsOfRoot(candidates, root_line) abort
  let candidates = filter(copy(a:candidates),
        \ 'has_key(v:val, ''scope'')'.
        \ ' && s:StartWith(v:val.scope, a:root_line.name)'.
        \ ' && v:val.scopeKind ==# a:root_line.kind'.
        \ ' && v:val.line >= a:root_line.line'
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

    let descendants = s:DescendantsOf(g:vista.with_scope, child_line, child_name)

    if !empty(descendants)
      call s:RenderDescendants(child_name, child_line, descendants, a:rows, depth)
    endif

    let idx += 1
  endwhile
endfunction

function! s:GetVisibility(line) abort
  return has_key(a:line, 'access') ? get(s:visibility_icon, a:line.access, '?') : ''
endfunction

function! s:SortCompare(i1, i2) abort
  return a:i1.name > a:i2.name
endfunction

function! s:RenderScopeless(scope_less, rows) abort
  let rows = a:rows
  let scope_less = a:scope_less

  for kind in keys(scope_less)
    let kind_line = vista#renderer#Decorate(kind)
    call add(rows, g:vista_fold_toggle_icons[0].' '.kind_line)

    let lines = scope_less[kind]

    if get(g:vista, 'sort', v:false)
      let lines = sort(copy(lines), function('s:SortCompare'))
    endif

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
    call add(s:vlnum_cache, '')
  endfor

  " Remove the last line if it's empty, i.e., ''
  if !empty(rows) && empty(rows[-1])
    unlet rows[-1]
  endif
endfunction

function! s:Render() abort
  let s:scope_seperator = g:vista.source.scope_seperator()

  let rows = []

  " s:vlnum_cache is a cache for recording which original tagline
  " is related to the line in the vista sidebar, for we have to
  " remove the duplicate parents which leads to reassign the lnum
  " to the original tagline.
  "
  " The item of s:vlnum_cache is some original tagline dict with
  " `vlnum` field added later.
  let s:vlnum_cache = []

  let scope_less = {}

  let without_scope = g:vista.without_scope

  " The root of hierarchy structure doesn't have scope field.
  for potential_root_line in without_scope

    let root_name = potential_root_line.name

    let descendants = s:DescendantsOfRoot(g:vista.with_scope, potential_root_line)

    if !empty(descendants)

      call s:RenderDescendants(root_name, potential_root_line, descendants, rows, 0)

      call add(rows, '')
      call add(s:vlnum_cache, '')

    else

      if has_key(potential_root_line, 'kind')
        call vista#util#TryAdd(scope_less, potential_root_line.kind, potential_root_line)
      endif

    endif

  endfor

  call s:RenderScopeless(scope_less, rows)

  " The original tagline is positioned in which line in the vista sidebar.
  let idx = 0
  while idx < len(s:vlnum_cache)
    if !empty(s:vlnum_cache[idx])
      " idx is 0-based, while the line number is 1-based, and we prepend the
      " two lines first, so the final offset is 1+2=3
      let s:vlnum_cache[idx].vlnum = idx + g:vista#renderer#default#vlnum_offset
    endif
    let idx += 1
  endwhile

  let g:vista.vlnum_cache = s:vlnum_cache

  return rows
endfunction

function! vista#renderer#hir#ctags#Render() abort
  if empty(g:vista.raw)
    return []
  endif

  return s:Render()
endfunction
