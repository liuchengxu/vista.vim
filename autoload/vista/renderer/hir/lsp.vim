" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:IntoLSPHirRow(row) abort
  let indent = repeat(' ', a:row.level * 2)
  let text = a:row.text
  let kind = a:row.kind
  let icon = vista#renderer#IconFor(a:row.kind)
  let lnum = ':'.a:row.lnum
  return indent.icon.' '.text.' '.kind.lnum
endfunction

function! s:IntoLSPNonHirRow(row) abort
  let indented = repeat(' ', 2).a:row.text
  let lnum = ':'.a:row.lnum
  let t:vista.lnum2tag[len(s:rendered)+3] = a:row.text
  let t:vista.slnum2tlnum[a:row.lnum] = len(s:rendered)+3
  return indented.lnum
endfunction

function! s:RenderLSPHirAndThenGroupByKind(data) abort
  let t:vista.lnum2tag = {}
  let t:vista.slnum2tlnum = {}

  let s:rendered = []
  let level0 = {}

  let idx = 0
  let len = len(a:data)

  for row in a:data
    if (row.level == 0 && idx+1 < len && a:data[idx+1].level > 0)
          \ || row.level > 0
      call add(s:rendered, s:IntoLSPHirRow(row))
      let t:vista.lnum2tag[len(s:rendered)+2] = row.text
      let t:vista.slnum2tlnum[row.lnum] = len(s:rendered)+2
    endif
    if row.level > 0
      if idx+1 < len && a:data[idx+1].level == 0
        call add(s:rendered, '')
        let t:vista.lnum2tag[len(s:rendered)+2] = v:null
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
    call add(s:rendered, vista#renderer#Decorate(kind))
    call map(vs, 'add(s:rendered, s:IntoLSPNonHirRow(v:val))')
    call add(s:rendered, '')
    let t:vista.lnum2tag[len(s:rendered)+2] = v:null
  endfor

  if empty(s:rendered[-1])
    unlet s:rendered[-1]
  endif

  return s:rendered
endfunction

" Render the content linewise.
function! s:TransformDirectly(row) abort
  let indented = repeat(' ', a:row.level * 4).a:row.text
  let kind = ' : '.vista#renderer#Decorate(a:row.kind)
  let lnum = ':'.a:row.lnum
  return indented.kind.lnum
endfunction

" data is a list of items with the level info for the hierarchy purpose.
function! vista#renderer#hir#lsp#Coc(data) abort
  " return map(a:data, 's:Transform(v:val)')
  return s:RenderLSPHirAndThenGroupByKind(a:data)
endfunction
