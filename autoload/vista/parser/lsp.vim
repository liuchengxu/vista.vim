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
endfunction

" https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
function! vista#parser#lsp#ExtractSymbol(symbol, container) abort
  let symbol = a:symbol

  let picked = {'lnum': symbol.lnum, 'col': symbol.col, 'text': symbol.text}

  if symbol.kind ==? 'Method' || symbol.kind ==? 'Function'
    call add(t:vista.functions, symbol)
  endif

  if has_key(a:container, symbol.kind)
    call add(a:container[symbol.kind], picked)
  else
    let a:container[symbol.kind] = [picked]
  endif
endfunction
