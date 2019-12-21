" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '~',
      \ 'private': '-',
      \ }

let g:vista_fold_toggle_icons = get(g:, 'vista_fold_toggle_icons', ['▼', '▶'])

function! s:GetVisibility(line) abort
  return has_key(a:line, 'access') ? get(s:visibility_icon, a:line.access, '?') : ''
endfunction

" Return the rendered row to be displayed given the depth
function! s:IntoCtagsRow(line, depth) abort
  let kind = get(a:line, 'kind', '')

  if !empty(kind)
    let kind = vista#renderer#Decorate(kind)
  endif

  let row = vista#util#Join(
        \ repeat(' ', a:depth * 4),
        \ s:GetVisibility(a:line),
        \ get(a:line, 'name'),
        \ get(a:line, 'signature', ''),
        \ ' : '.kind,
        \ ':'.get(a:line, 'line', '')
        \ )

  return row
endfunction

function! s:CompareByLine(i1, i2) abort
  return a:i1.line > a:i2.line
endfunction

function! s:AppendRowAtDepth(rows, tag_info, depth) abort
  let rows = a:rows

  call add(rows, s:IntoCtagsRow(a:tag_info, a:depth))

  let line = a:tag_info
  let line.vlnum = len(rows) + 2
endfunction

function! s:RenderCtags(rows, tag_info, children, depth) abort
  let rows = a:rows

  call s:AppendRowAtDepth(rows, a:tag_info, a:depth)

  if !empty(a:children)
    for child in sort(copy(a:children), function('s:CompareByLine'))
      let parent_id = child.tree_id
      if has_key(t:vista.tree, parent_id)
        let children = t:vista.tree[parent_id]
        call s:RenderCtags(rows, child, children, a:depth+1)
      else
        call s:AppendRowAtDepth(rows, child, a:depth + 1)
      endif
    endfor
  endif
endfunction

function! s:SortCompare(i1, i2) abort
  return a:i1.name > a:i2.name
endfunction

function! s:RenderByKind(scope_less, rows) abort
  let rows = a:rows
  let scope_less = a:scope_less

  for [kind, lines] in items(scope_less)
    let kind_line = vista#renderer#Decorate(kind)
    call add(rows, g:vista_fold_toggle_icons[0].' '.kind_line)

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

function! vista#renderer#hir#ctags#Render() abort
  let rows = []
  let kind_group = {}

  for [parent_id, parent] in items(t:vista.parents)
    if has_key(t:vista.tree, parent_id)
      let children = t:vista.tree[parent_id]
      call s:RenderCtags(rows, parent, children, 0)
      call add(rows, '')
    else
      if has_key(kind_group, parent.kind)
        call add(kind_group[parent.kind], parent)
      else
        let kind_group[parent.kind] = [parent]
      endif
    endif
  endfor

  call s:RenderByKind(kind_group, rows)

  return rows
endfunction
