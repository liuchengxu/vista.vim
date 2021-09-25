" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:indent_size = g:vista#renderer#enable_icon ? 2 : 4

function! s:IntoLSPHirRow(row) abort
  let indent = repeat(' ', a:row.level * s:indent_size)
  let kind_icon = vista#renderer#IconFor(a:row.kind)
  let kind_text = vista#renderer#KindFor(a:row.kind)

  " indent + kind_icon? + name + kind_text? + lnum
  let line = indent
  if !empty(kind_icon)
    let line = line.kind_icon.' '
  endif
  let line = line.a:row.text
  if !empty(kind_text)
    let line = line.' '.kind_text
  endif
  return line.':'.a:row.lnum
endfunction

function! s:IntoLSPNonHirRow(row) abort
  let indented = repeat(' ', s:indent_size).a:row.text
  let lnum = ':'.a:row.lnum
  return indented.lnum
endfunction

function! s:RenderNonHirRow(vs, rendered) abort
  call add(a:rendered, s:IntoLSPNonHirRow(a:vs.row))
  let vlnum = len(a:rendered) + 2
  let g:vista.raw[a:vs.idx].vlnum = vlnum
  if has_key(a:vs.row, 'text')
    let g:vista.vlnum2tagname[vlnum] = a:vs.row.text
  endif
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
      let g:vista.raw[idx].vlnum = len(rendered) + 2
      if has_key(row, 'text')
        let g:vista.vlnum2tagname[len(rendered)+2] = row.text
      endif
    endif
    if row.level > 0
      if idx+1 < len && a:data[idx+1].level == 0
        call add(rendered, '')
      endif
    else
      if idx < len && a:data[idx].level == 0
        if has_key(level0, row.kind)
          call add(level0[row.kind], { 'row': row, 'idx': idx })
        else
          let level0[row.kind] = [{ 'row': row, 'idx': idx }]
        endif
      endif
    endif
    let idx += 1
  endfor

  if len(level0) > 0 && !empty(rendered) && rendered[-1] !=# ''
    call add(rendered, '')
  endif

  for [kind, vs] in items(level0)
    call add(rendered, vista#renderer#Decorate(kind))
    call map(vs, 's:RenderNonHirRow(v:val, rendered)')
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
  let g:vista.vlnum2tagname = {}
  " return map(a:data, 's:Transform(v:val)')
  return s:RenderLSPHirAndThenGroupByKind(a:data)
endfunction
