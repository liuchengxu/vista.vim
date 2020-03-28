" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:indent_size = g:vista#renderer#enable_icon ? 2 : 4

function! s:IntoLSPHirRow(row) abort
  let icon = vista#renderer#IconFor(a:row.kind).' '
  let indented = repeat(' ', a:row.level * s:indent_size).icon.a:row.text.' '.a:row.kind
  let lnum = ':'.a:row.lnum
  return indented.lnum
endfunction

function! s:IntoLSPNonHirRow(row) abort
  let indented = repeat(' ', s:indent_size).a:row.text
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
  let icon = vista#renderer#IconFor(a:row.kind)
  let indented = repeat(' ', a:row.level * s:indent_size).icon.a:row.text
  let lnum = ':'.a:row.lnum
  return indented.kind.lnum
endfunction

" data is a list of items with the level info for the hierarchy purpose.
function! vista#renderer#hir#lsp#Coc(data) abort
  " return map(a:data, 's:Transform(v:val)')
  return s:RenderLSPHirAndThenGroupByKind(a:data)
endfunction
