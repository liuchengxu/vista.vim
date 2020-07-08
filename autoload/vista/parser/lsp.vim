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
  for lspsym in a:symbols
    let l:loc = lspsym.location
    if s:IsFileUri(l:loc.uri)
      call add(a:outlist, s:LspToLocalSymbol(lspsym, l:loc.range))
    endif
  endfor
endfunction

function! s:ParseDocumentSymbolsRec(outlist, symbols, level) abort
  for lspsym in a:symbols
    let l:sym = s:LspToLocalSymbol(lspsym, lspsym.selectionRange)
    let l:sym.level = a:level
    call add(a:outlist, l:sym)
    if has_key(lspsym, 'children')
      call s:ParseDocumentSymbolsRec(a:outlist, lspsym.children, a:level + 1)
    endif
  endfor
endfunction

function! s:GroupSymbolsByKind(symbols) abort
  let l:groups = {}
  for l:sym in a:symbols
    if has_key(l:groups, l:sym.kind)
      call add(l:groups[l:sym.kind], l:sym)
    else
      let l:groups[l:sym.kind] = [ l:sym ]
    endif
  endfor
  return l:groups
endfunction

function! vista#parser#lsp#ParseDocumentSymbolPayload(resp) abort
  let l:symbols = []
  if s:IsDocumentSymbol(a:resp[0])
    call s:ParseDocumentSymbolsRec(l:symbols, a:resp, 0)
    call vista#parser#lsp#FilterDocumentSymbols(l:symbols)
    call vista#parser#lsp#DispatchDocumentSymbols(l:symbols)
    return l:symbols
  else
    call s:ParseSymbolInfoList(l:symbols, a:resp)
    call vista#parser#lsp#FilterDocumentSymbols(l:symbols)
    return s:GroupSymbolsByKind(l:symbols)
  endif
endfunction

function! vista#parser#lsp#FilterDocumentSymbols(symbols) abort
  let l:symlist = a:symbols
  if exists('g:vista_ignore_kinds')
    call filter(l:symlist, 'index(g:vista_ignore_kinds, v:val) < 0')
  endif
  let g:vista.functions = []
  for l:sym in l:symlist
    if l:sym.kind ==? 'Method' || l:sym.kind ==? 'Function'
      call add(g:vista.functions, l:sym)
    endif
  endfor
  return l:symlist
endfunction

function! vista#parser#lsp#DispatchDocumentSymbols(symbols)
  let g:vista.raw = map(copy(a:symbols), { _, sym -> s:LocalToRawSymbol(sym) })
  return g:vista.raw
endfunction

function! vista#parser#lsp#CocSymbols(symbol, container) abort
  if vista#ShouldIgnore(a:symbol.kind)
    return
  endif

  call add(g:vista.raw, s:LocalToRawSymbol(a:symbol))

  if a:symbol.kind ==? 'Method' || a:symbol.kind ==? 'Function'
    call add(g:vista.functions, a:symbol)
  endif

  call add(a:container, copy(a:symbol))
endfunction
