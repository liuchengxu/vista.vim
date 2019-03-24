" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:Insert(container, kind, picked) abort
  if has_key(a:container, a:kind)
    call add(a:container[a:kind], a:picked)
  else
    let a:container[a:kind] = [a:picked]
  endif
endfunction

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
function! vista#parser#ctags#ExtractTag(line, container) abort
  " {tagname}<Tab>{tagfile}<Tab>{tagaddress}[;"<Tab>{tagfield}..]
  " {tagname}<Tab>{tagfile}<Tab>{tagaddress};"<Tab>{kind}<Tab>{scope}
  " ['vista#executive#ctags#Execute', '/Users/xlc/.vim/plugged/vista.vim/autoload/vista/executive/ctags.vim', '84;"', 'function']
  let items = split(a:line, '\t')

  let tagname = items[0]
  let tagfile = items[1]
  let lnum = split(items[2], ';')[0]
  let scope = items[-1]

  let picked = {'lnum': lnum, 'text': tagname}

  if scope =~# '^f'
    call add(t:vista.functions, picked)
  endif

  call s:Insert(a:container, scope, picked)
endfunction

function! vista#parser#ctags#TagFromJSON(line, container) abort
  let line = json_decode(a:line)

  let kind = line.kind

  let picked = {'lnum': line.line, 'text': line.name }

  if kind ==? 'function' || kind ==? 'func'
    call add(t:vista.functions, picked)
  endif

  call s:Insert(a:container, kind, picked)
endfunction

function! vista#parser#ctags#ProjectTagFromXformat(line, container) abort
  " let cmd = "ctags -R -x --_xformat='TAGNAME:%N ++++ KIND:%K ++++ LINE:%n ++++ INPUT-FILE:%F ++++ PATTERN:%P'"

  if a:line =~ '^ctags: Warning: ignoring null tag'
    return
  endif

  let items = split(a:line, '++++')

  if len(items) != 5
    call vista#error#('Splitted items is not expected: '.string(items))
    return
  endif

  call map(items, 'vista#util#Trim(v:val)')

  " TAGNAME:
  let tagname = items[0][8:]
  " KIND:
  let kind = items[1][5:]
  " LINE:
  let lnum = items[2][5:]
  " INPUT-FILE:
  let relpath = items[3][11:]
  " PATTERN:
  let pattern = items[4][8:]

  let picked = {'lnum': lnum, 'text': tagname, 'tagfile': relpath, 'taginfo': pattern[2:-3]}

  call s:Insert(a:container, kind, picked)
endfunction

function! vista#parser#ctags#ProjectTagFromJSON(line, container) abort
  " {
  "  "_type":"tag",
  "  "name":"vista#source#Update",
  "  "path":"autoload/vista/source.vim",
  "  "pattern":"/^function! vista#source#Update(bufnr, winnr, ...) abort$/",
  "  "line":29,
  "  "kind":"function"
  " }
  let line = json_decode(a:line)

  let kind = line.kind

  let picked = {'lnum': line.line, 'text': line.name, 'tagfile': line.path, 'taginfo': line.pattern[2:-3]}

  call s:Insert(a:container, kind, picked)
endfunction
