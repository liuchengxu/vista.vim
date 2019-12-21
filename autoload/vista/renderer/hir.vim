" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:IntoLSPHirRow(row) abort
  let indented = repeat(' ', a:row.level * 4).a:row.text
  let kind = ' : '.vista#renderer#Decorate(a:row.kind)
  let lnum = ':'.a:row.lnum
  return indented.kind.lnum
endfunction

function! s:IntoLSPNonHirRow(row) abort
  let indented = repeat(' ', 4).a:row.text
  let lnum = ':'.a:row.lnum
  return indented.lnum
endfunction

function! s:RenderLSPHirAndThenGroupByKind(data) abort
  let rendered = []
  let level0 = {}

  let idx = 0
  let len = len(a:data)

  for row in a:data
    if (row.level == 0 && idx+1 < len && a:data[idx+1].level > 0)
          \ || row.level > 0
      call add(rendered, s:IntoLSPHirRow(row))
    endif
    if row.level > 0
      if idx+1 < len && a:data[idx+1].level == 0
        call add(rendered, '')
      endif
    else
      if idx+1 < len && a:data[idx+1].level == 0
        if has_key(level0, row.kind)
          call add(level0[row.kind], row)
        else
          let level0[row.kind] = [row]
        endif
      endif
    endif
    let idx += 1
  endfor

  for [kind, vs] in items(level0)
    call add(rendered, vista#renderer#Decorate(kind))
    call map(vs, 'add(rendered, s:IntoLSPNonHirRow(v:val))')
    call add(rendered, '')
  endfor

  if empty(rendered[-1])
    unlet rendered[-1]
  endif

  return rendered
endfunction

" Render the content linewise.
function! s:TransformDirectly(row) abort
  let indented = repeat(' ', a:row.level * 4).a:row.text
  let kind = ' : '.vista#renderer#Decorate(a:row.kind)
  let lnum = ':'.a:row.lnum
  return indented.kind.lnum
endfunction

" data is a list of items with the level info for the hierarchy purpose.
function! vista#renderer#hir#Coc(data) abort
  " return map(a:data, 's:Transform(v:val)')
  return s:RenderLSPHirAndThenGroupByKind(a:data)
endfunction

function! s:Render(rows, tag_info, children, depth) abort
  let rows = a:rows
  let row = repeat(' ', a:depth * 4).a:tag_info['name'].' :'.a:tag_info['kind'].':'.a:tag_info['line']
  call add(rows, row)
  if !empty(a:children)
    for child in a:children

      " let treeId = join([child.scope, child.name], t:vista.source.scope_seperator())
      " if has_key(t:vista.tree, treeId)
        " let children = t:vista.tree[treeId].children
        " let children = filter(children, 'v:val["line"] >= a:tag_info["line"]')
        " call s:Render(rows, child, children, a:depth + 1)
      " else
        " call s:Render(rows, child, [], a:depth + 1)
      " endif

      let parent_id = join([child.name, child.kind], '|')
      let parent_id = child.tree_id
      echom "child:".string(child)
      echom "parent_id:".parent_id
      echom "t:vista.tree.parent_id:".get(t:vista.tree, 'parent_id', 'NO')
      if has_key(t:vista.tree, parent_id)
        let children = t:vista.tree[parent_id]
        call s:Render(rows, child, children, a:depth+1)
      else
        call s:Render(rows, child, [], a:depth +1)
      endif
    endfor
  endif
endfunction

function! vista#renderer#hir#Ctags() abort
  let rows = []
  let kind_group = {}

  for [parent_id, parent] in items(t:vista.parents)
    if has_key(t:vista.tree, parent_id)
      let children = t:vista.tree[parent_id]
      call s:Render(rows, parent, children, 0)
    else
      if has_key(kind_group, parent.kind)
        call add(kind_group[parent.kind], parent)
      else
        let kind_group[parent.kind] = [parent]
      endif
    endif
  endfor

  " for root in t:vista.without_scope
    " let root_name = root.name
    " if has_key(t:vista.tree, root_name)
      " let children = t:vista.tree[root_name].children
      " call s:Render(rows, root, children, 0)
    " else
      " if has_key(kind_group, root.kind)
        " call add(kind_group[root.kind], root)
      " else
        " let kind_group[root.kind] = [root]
      " endif
    " endif
  " endfor

  for [key, vals] in items(kind_group)
    call add(rows, key.':')
    for val in vals
      call add(rows, repeat(' ', 4).val['name'].' :'.val['line'])
    endfor
  endfor

  return rows
endfunction
