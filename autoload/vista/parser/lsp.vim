" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
" This should be updated periodically according the latest LSP specification.
let s:symbol_kind = {
    \ '1': 'File',
    \ '2': 'Module',
    \ '3': 'Namespace',
    \ '4': 'Package',
    \ '5': 'Class',
    \ '6': 'Method',
    \ '7': 'Property',
    \ '8': 'Field',
    \ '9': 'Constructor',
    \ '10': 'Enum',
    \ '11': 'Interface',
    \ '12': 'Function',
    \ '13': 'Variable',
    \ '14': 'Constant',
    \ '15': 'String',
    \ '16': 'Number',
    \ '17': 'Boolean',
    \ '18': 'Array',
    \ '19': 'Object',
    \ '20': 'Key',
    \ '21': 'Null',
    \ '22': 'EnumMember',
    \ '23': 'Struct',
    \ '24': 'Event',
    \ '25': 'Operator',
    \ '26': 'TypeParameter',
    \ }

function! s:Kind2Symbol(kind) abort
  return has_key(s:symbol_kind, a:kind) ? s:symbol_kind[a:kind] : 'Unknown kind '.a:kind
endfunction

function! s:IsFileUri(uri) abort
  return stridx(a:uri, 'file:///') == 0
endfunction

" The kind field in the result is a number instead of a readable text, we
" should transform the number to the symbol text first.
function! vista#parser#lsp#KindToSymbol(line, container) abort
  let line = a:line
  " SymbolInformation interface
  if has_key(line, 'location')
    let location = line.location
    if s:IsFileUri(location.uri)
      let lnum = location.range.start.line + 1
      let col = location.range.start.character + 1
      call add(a:container, {
         \ 'lnum': lnum,
         \ 'col': col,
         \ 'kind': s:Kind2Symbol(line.kind),
         \ 'text': line.name,
         \ })
    endif
  " DocumentSymbol class
  elseif has_key(line, 'range')
    let range = line.range
    let lnum = range.start.line + 1
    let col = range.start.character + 1
    call add(a:container, {
          \ 'lnum': lnum,
          \ 'col': col,
          \ 'kind': s:Kind2Symbol(line.kind),
          \ 'text': line.name,
          \ })
    if has_key(line, 'children')
      for child in line.children
        call vista#parser#lsp#KindToSymbol(child, a:container)
      endfor
    endif
  endif
endfunction

function! vista#parser#lsp#CocSymbols(symbol, container) abort
  if vista#ShouldIgnore(a:symbol.kind)
    return
  endif

  let raw = { 'line': a:symbol.lnum, 'kind': a:symbol.kind, 'name': a:symbol.text }
  call add(g:vista.raw, raw)

  if a:symbol.kind ==? 'Method' || a:symbol.kind ==? 'Function'
    call add(g:vista.functions, a:symbol)
  endif

  call add(a:container, {
        \ 'lnum': a:symbol.lnum,
        \ 'col': a:symbol.col,
        \ 'text': a:symbol.text,
        \ 'kind': a:symbol.kind,
        \ 'level': a:symbol.level
        \ })
endfunction

" https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
function! vista#parser#lsp#ExtractSymbol(symbol, container) abort
  let symbol = a:symbol

  if vista#ShouldIgnore(symbol.kind)
    return
  endif

  if symbol.kind ==? 'Method' || symbol.kind ==? 'Function'
    call add(g:vista.functions, symbol)
  endif

  let picked = {'lnum': symbol.lnum, 'col': symbol.col, 'text': symbol.text}

  if has_key(a:container, symbol.kind)
    call add(a:container[symbol.kind], picked)
  else
    let a:container[symbol.kind] = [picked]
  endif
endfunction
