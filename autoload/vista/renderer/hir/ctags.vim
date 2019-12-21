" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:visibility_icon = {
      \ 'public': '+',
      \ 'protected': '~',
      \ 'private': '-',
      \ }

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

function! s:RenderCtags(rows, tag_info, children, depth) abort
  let rows = a:rows
  call add(rows, s:IntoCtagsRow(a:tag_info, a:depth))
  if !empty(a:children)
    for child in a:children
      let parent_id = child.tree_id
      if has_key(t:vista.tree, parent_id)
        let children = t:vista.tree[parent_id]
        call s:RenderCtags(rows, child, children, a:depth+1)
      else
        call s:RenderCtags(rows, child, [], a:depth +1)
      endif
    endfor
  endif
endfunction

function! vista#renderer#hir#ctags#Render() abort
  let rows = []
  let kind_group = {}

  for [parent_id, parent] in items(t:vista.parents)
    if has_key(t:vista.tree, parent_id)
      let children = t:vista.tree[parent_id]
      call s:RenderCtags(rows, parent, children, 0)
    else
      if has_key(kind_group, parent.kind)
        call add(kind_group[parent.kind], parent)
      else
        let kind_group[parent.kind] = [parent]
      endif
    endif
  endfor

  for [key, vals] in items(kind_group)
    call add(rows, key.':')
    for val in vals
      call add(rows, repeat(' ', 4).val['name'].' :'.val['line'])
    endfor
  endfor

  return rows
endfunction
