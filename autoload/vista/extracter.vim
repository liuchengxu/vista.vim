" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Parse the output from ctags linewise and feed them into the container
" The parsed result should be compatible with the LSP output.
"
" Currently we only use these fields:
"
" {
"   'lnum': 12,
"   'col': 8,
"   'kind': 'Function',
"   'text': 'testnet_genesis',
" }
"
function! vista#extracter#ExtractTag(line, container) abort
  " {tagname}<Tab>{tagfile}<Tab>{tagaddress}[;"<Tab>{tagfield}..]
  " {tagname}<Tab>{tagfile}<Tab>{tagaddress};"<Tab>{kind}<Tab>{scope}
  " ['vista#executive#ctags#Execute', '/Users/xlc/.vim/plugged/vista.vim/autoload/vista/executive/ctags.vim', '84;"', 'function']
  let items = split(a:line, '\t')

  let tagname = items[0]
  let tagfile = items[1]
  let lnum = split(items[2], ';')[0]
  let scope = items[-1]

  let picked = {'lnum': lnum, 'text': tagname}

  if has_key(a:container, scope)
    call add(a:container[scope], picked)
  else
    let a:container[scope] = [picked]
  endif
endfunction

function! vista#extracter#ExtractProjectTag(line, container) abort
  let g:line = a:line
  let lnum_idx = match(a:line, '\<\d\+\>')
  let lnum = matchstr(a:line, '\<\d\+\>')
  let [tagname, scope] = filter(split(a:line[:lnum_idx-1], '\s'), '!empty(v:val)')
  let rest = split(a:line[lnum_idx+len(lnum):], '\s')
  let tagfile = rest[0]
  let taginfo = join(rest[1:])

  let picked = {'lnum': lnum, 'text': tagname, 'tagfile': tagfile, 'taginfo': taginfo}

  if has_key(a:container, scope)
    call add(a:container[scope], picked)
  else
    let a:container[scope] = [picked]
  endif
endfunction

" https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol
function! vista#extracter#ExtractSymbol(symbol, container) abort
  let symbol = a:symbol

  let picked = {'lnum': symbol.lnum, 'col': symbol.col, 'text': symbol.text}

  if has_key(a:container, symbol.kind)
    call add(a:container[symbol.kind], picked)
  else
    let a:container[symbol.kind] = [picked]
  endif
endfunction
