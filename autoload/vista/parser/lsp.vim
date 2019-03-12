" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
function! vista#parser#lsp#ExtractSymbol(symbol, container) abort
  let symbol = a:symbol

  let picked = {'lnum': symbol.lnum, 'col': symbol.col, 'text': symbol.text}

  if has_key(a:container, symbol.kind)
    call add(a:container[symbol.kind], picked)
  else
    let a:container[symbol.kind] = [picked]
  endif
endfunction
