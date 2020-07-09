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

" The kind field in the result is a number instead of a readable text, we
" should transform the number to the symbol text first.
function! s:Kind2Symbol(kind) abort
  return has_key(s:symbol_kind, a:kind) ? s:symbol_kind[a:kind] : 'Unknown kind '.a:kind
endfunction

function! s:IsFileUri(uri) abort
  return stridx(a:uri, 'file:///') == 0
endfunction

function! s:LspToLocalSymbol(sym, range)
  return {
    \ 'lnum': a:range.start.line + 1,
    \ 'col': a:range.start.character + 1,
    \ 'kind': s:Kind2Symbol(a:sym.kind),
    \ 'text': a:sym.name,
    \ }
endfunction

function! s:LocalToRawSymbol(sym)
  return {
    \ 'line': a:sym.lnum,
    \ 'kind': a:sym.kind,
    \ 'name': a:sym.text,
    \ }
endfunction

function! s:IsDocumentSymbol(sym)
  return has_key(a:sym, 'selectionRange')
endfunction

function! s:ParseSymbolInfoList(outlist, symbols) abort
  let filtered = filter(a:symbols, 's:IsFileUri(v:val.location.uri)')
  return map(filtered, 's:LspToLocalSymbol(v:val, v:val.location.range)')
endfunction

function! s:ParseDocumentSymbolsRec(outlist, symbols, level) abort
  for lspsym in a:symbols
    let sym = s:LspToLocalSymbol(lspsym, lspsym.selectionRange)
    let sym.level = a:level
    call add(a:outlist, sym)
    if has_key(lspsym, 'children')
      call s:ParseDocumentSymbolsRec(a:outlist, lspsym.children, a:level + 1)
    endif
  endfor
  return a:outlist
endfunction

function! s:GroupSymbolsByKind(symbols) abort
  let groups = {}
  for sym in a:symbols
    if has_key(groups, sym.kind)
      call add(groups[sym.kind], sym)
    else
      let groups[sym.kind] = [ sym ]
    endif
  endfor
  return groups
endfunction

function! vista#parser#lsp#ParseDocumentSymbolPayload(resp) abort
  if s:IsDocumentSymbol(a:resp[0])
    let symbols = s:ParseDocumentSymbolsRec([], a:resp, 0)
    return vista#parser#lsp#DispatchDocumentSymbols(symbols)
  else
    let symbols = s:ParseSymbolInfoList(a:resp)
    call s:FilterDocumentSymbols(symbols)
    return s:GroupSymbolsByKind(symbols)
  endif
endfunction

function! s:FilterDocumentSymbols(symbols) abort
  let symlist = a:symbols
  if exists('g:vista_ignore_kinds')
    call filter(symlist, 'index(g:vista_ignore_kinds, v:val) < 0')
  endif
  let g:vista.functions =
    \ filter(copy(symlist), 'v:val.kind ==? "Method" || v:val.kind ==? "Function"')
  return symlist
endfunction

function! vista#parser#lsp#DispatchDocumentSymbols(symbols)
  let symlist = s:FilterDocumentSymbols(a:symbols)
  let g:vista.raw = map(copy(symlist), { _, sym -> s:LocalToRawSymbol(sym) })
  return symlist
endfunction
