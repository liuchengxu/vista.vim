" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:scope_icon = ['⊕', '⊖']

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '~',
      \ 'private': '-',
      \ }

let g:vista#renderer#default#vlnum_offset = 3

" Given a string to diplay.
" Return the string padded with spaces given the depth
function! s:Pad(depth, str) abort
  return vista#util#Join(repeat(' ', a:depth * 4), a:str)
endfunction

function! s:GetDecoratedKind(line_dict) abort
  let kind = get(a:line_dict, 'kind', '')
  if !empty(kind)
    let kind = vista#renderer#Decorate(kind)
  endif
  return kind
endfunction

" Append line number
function! s:AppendLineNr(line_dict, row) abort
  let row = a:row
  let lnum = get(a:line_dict, 'line', '')
  if !empty(lnum)
    let row .= ':'.lnum
  endif
  return row
endfunction

" Return the rendered row to be displayed given the depth
function! s:AssembleDisplayRow(line, depth) abort
  let line = a:line

  let common = s:Pad(a:depth,
        \ vista#util#Join(
        \   s:GetVisibility(line),
        \   get(line, 'name'),
        \   get(line, 'signature', ''),
        \ ))

  if s:tag_kind_position ==# 'group'
    let row = common
  else
    " Show the kind of tag inline
    let kind = s:GetDecoratedKind(line)
    if !empty(kind)
      let row = vista#util#Join(common, ' : '.kind)
    endif
  endif

  let row = s:AppendLineNr(line, row)

  if a:depth == 0
    if s:tag_kind_position ==# 'group'
      let kind = s:GetDecoratedKind(line)
      if !empty(kind)
        let row .= ' ['.kind.']'
      endif
    endif
  endif

  return row
endfunction

" Actually append to the rows
function! s:Append(line, rows, depth) abort
  let line = a:line
  let rows = a:rows

  let row = s:AssembleDisplayRow(line, a:depth)

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

function! s:MockAppendChild(line, rows, depth) abort
  if has_key(a:line, 'scope')
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

  return {}
endfunction

" Find all descendants of the root
function! s:DescendantsOf(candidates, root_line, scope) abort
  let candidates = filter(copy(a:candidates),
        \ 'has_key(v:val, ''scope'')'.
        \ ' && v:val.scope =~# ''^''.a:scope'.
        \ ' && v:val.scopeKind ==# a:root_line.kind'.
        \ ' && v:val.line > a:root_line.line'
        \ )

  return candidates
  " The real parent problem seemingly has been solved?
  " return filter(candidates, 's:RealParentOf(v:val) ==# a:root_line')
endfunction

function! s:DescendantsOfRoot(candidates, root_line) abort
  let candidates = filter(copy(a:candidates),
        \ 'has_key(v:val, ''scope'')'.
        \ ' && v:val.scope =~# ''^''.a:root_line.name'.
        \ ' && v:val.scopeKind ==# a:root_line.kind'.
        \ ' && v:val.line > a:root_line.line'
        \ )

  return filter(candidates, 's:RealParentOf(v:val) ==# a:root_line')
endfunction

" Is this line the group icon, e.g,
"     [function]
function! s:IsGroupIconLine(row) abort
  return a:row =~? '^\s\+\[.*\]$'
endfunction

" Some items having the children will be duplicated possibly.
" So the current workaround is to remove these duplicated ones at last.
function! s:RemoveDuplicateLines(rows) abort
  let rows = a:rows

  let i = 0
  while i < len(rows)
    if s:IsGroupIconLine(rows[i])
      let i += 1
      continue
    endif

    let j = i+1
    while j < len(rows)
      if rows[j] == rows[i]

        unlet rows[i]
        if i < len(s:vlnum_cache)
          unlet s:vlnum_cache[i]
        endif

        if i > 0
          let prev_row = rows[i-1]
          if s:IsGroupIconLine(prev_row)
            unlet rows[i-1]
            unlet s:vlnum_cache[i-1]

            " The later duplicated item as well as its group icon is retained.
            call insert(rows, prev_row, j-2)
            call insert(s:vlnum_cache, '', j-2)
          endif
        endif

      endif
      let j += 1
    endwhile

    let i += 1
  endwhile
endfunction

function! s:RenderDescendants(parent_name, parent_line, descendants, rows, depth) abort
  let depth = a:depth
  let rows = a:rows

  let about_to_append = s:AssembleDisplayRow(a:parent_line, depth)

  " Append the root actually
  call s:ApplyAppend(a:parent_line, about_to_append, rows)

  let depth += 1

  " find all the children
  let children = filter(copy(a:descendants), 'v:val.scope ==# a:parent_name')

  let grandchildren = []
  let grandchildren_line = []

  let children_to_append = []
  let children_dict = {}

  for child in children

    if s:tag_kind_position ==# 'group'
      let [next_potentioal_root, next_potentioal_root_line] = s:MockAppendChild(child, rows, depth)
      if has_key(children_dict, child.kind)
        call add(children_to_append, child)
        call add(children_dict[child.kind], child)
      else
        let children_dict[child.kind] = [child]
      endif
    else
      let [next_potentioal_root, next_potentioal_root_line] = s:AppendChild(child, rows, depth)
    endif

    if !empty(next_potentioal_root)
      call add(grandchildren, next_potentioal_root)
      call add(grandchildren_line, next_potentioal_root_line)
    endif

  endfor

  if s:tag_kind_position ==# 'group'
    for group in keys(children_dict)
      if !empty(children_dict[group])
        let kind = vista#renderer#Decorate(group)
        let row = s:Pad(depth, '['.kind.']')
        let line = ''
        call add(rows, row)
        call add(s:vlnum_cache, line)
        for child in children_dict[group]
          call s:Append(child, rows, depth)
        endfor
      endif
    endfor
  endif

  let idx = 0
  while idx < len(grandchildren)
    let child_name = grandchildren[idx]
    let child_line = grandchildren_line[idx]

    let descendants = s:DescendantsOf(t:vista.with_scope, child_line, child_name)

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
    call add(rows, vista#renderer#Decorate(kind))

    let lines = scope_less[kind]

    if get(t:vista, 'sort', v:false)
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
  endfor

  " Remove the last line if it's empty, i.e., ''
  if !empty(rows) && empty(rows[-1])
    unlet rows[-1]
  endif
endfunction

function! s:Render() abort
  let s:scope_seperator = t:vista.source.scope_seperator()

  " group, inline
  let s:tag_kind_position = get(g:, 'vista_tag_kind_position', 'group')

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

  let without_scope = t:vista.without_scope

  " Build psedu tags for cpp anonymous namespace tags . Ref #83
  let ft_having_anonymous_tags = ['cpp', 'c']
  if index(ft_having_anonymous_tags, t:vista.source.filetype()) > -1
    let anons = []

    for ws in t:vista.with_scope
      if ws.scope =~# '^__anon' && index(anons,  ws.scope) == -1
        call add(anons, ws.scope)
      endif
    endfor

    let psedu_anonymous_cpp_namespace_tags = []

    for anon in anons
      let ps = filter(copy(t:vista.with_scope), 'v:val.scope ==# anon')
      let p = ps[0]
      let line = str2nr(p.line) - 1
      call add(psedu_anonymous_cpp_namespace_tags, { 'name': p.scope, 'kind': p.scopeKind, 'line': line })
    endfor

    call extend(without_scope, psedu_anonymous_cpp_namespace_tags)
  endif

  " The root of hierarchy structure doesn't have scope field.
  for potential_root_line in without_scope

    let root_name = potential_root_line.name

    let descendants = s:DescendantsOfRoot(t:vista.with_scope, potential_root_line)

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

  call s:RemoveDuplicateLines(rows)

  " FIXME why needs twice?
  call s:RemoveDuplicateLines(rows)

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

  let t:vista.vlnum_cache = s:vlnum_cache

  return rows
endfunction

function! vista#renderer#default#Render() abort
  if empty(t:vista.raw)
    return []
  endif

  return s:Render()
endfunction
