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

function! s:ShortToLong(short) abort
  let ft = getbufvar(t:vista.source.bufnr, '&filetype')

  try

    let types = g:vista#types#uctags#{ft}#
    if has_key(types.kinds, a:short)
      return types.kinds[a:short]['long']
    endif
  catch /^Vim\%((\a\+)\)\=:E121/
  endtry

  return a:short
endfunction

function! s:ParseTagfield(tagfields) abort
  let fields = {}

  if stridx(a:tagfields[0], ':') > -1
    let colon = stridx(a:tagfields[0], ':')
    let value = tagfield[colon+1:]
    let fields.kind = value
  else
    let kind = s:ShortToLong(a:tagfields[0])
    let fields.kind = kind
    if index(t:vista.kinds, kind) == -1
      call add(t:vista.kinds, kind)
    endif
  endif

  if len(a:tagfields) > 1
    for tagfield in a:tagfields[1:]
      let colon = stridx(tagfield, ':')
      let name = tagfield[0:colon-1]
      let value = tagfield[colon+1:]
      let fields[name] = value
    endfor
  endif

  return fields
endfunction

" {tagname}<Tab>{tagfile}<Tab>{tagaddress}[;"<Tab>{tagfield}..]
" {tagname}<Tab>{tagfile}<Tab>{tagaddress};"<Tab>{kind}<Tab>{scope}
" ['vista#executive#ctags#Execute', '/Users/xlc/.vim/plugged/vista.vim/autoload/vista/executive/ctags.vim', '84;"', 'function']
function! vista#parser#ctags#FromExtendedRaw(line, container) abort
  if a:line =~# '^!_TAG'
    return
  endif
  let items = split(a:line, '\t')

  let line = {}

  let line.name = items[0]
  let line.tagfile = items[1]
  let line.tagaddress = items[2]

  let tagfields = s:ParseTagfield(items[3:])

  call extend(line, tagfields)

  let kind = line.kind

  let picked = {'lnum': line.line, 'text': line.name}

  if kind =~# '^f' || kind =~# '^m'
    if has_key(line, 'signature')
      let picked.signature = line.signature
    endif
    call add(t:vista.functions, picked)
  endif

  call s:Insert(a:container, kind, picked)

endfunction

function! vista#parser#ctags#FromJSON(line, container) abort
  let line = json_decode(a:line)

  call add(t:vista.raw, line)

  let kind = line.kind

  let picked = {'lnum': line.line, 'text': line.name }

  if kind =~# '^f' || kind =~# '^m'
    if has_key(line, 'signature')
      let picked.signature = line.signature
    endif
    call add(t:vista.functions, picked)
  endif

  if index(t:vista.kinds, kind) == -1
    call add(t:vista.kinds, kind)
  endif

  call s:Insert(a:container, kind, picked)
endfunction

" ctags -R -x --_xformat='TAGNAME:%N ++++ KIND:%K ++++ LINE:%n ++++ INPUT-FILE:%F ++++ PATTERN:%P'"
"
function! vista#parser#ctags#RecursiveFromXformat(line, container) abort

  if a:line =~# '^ctags: Warning: ignoring null tag'
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

function! vista#parser#ctags#RecursiveFromJSON(line, container) abort
  " {
  "  "_type":"tag",
  "  "name":"vista#source#Update",
  "  "path":"autoload/vista/source.vim",
  "  "pattern":"/^function! vista#source#Update(bufnr, winnr, ...) abort$/",
  "  "line":29,
  "  "kind":"function"
  " }
  if a:line =~# '^ctags: Warning: ignoring null tag'
    return
  endif

  let line = json_decode(a:line)

  let kind = line.kind

  let picked = {'lnum': line.line, 'text': line.name, 'tagfile': line.path, 'taginfo': line.pattern[2:-3]}

  call s:Insert(a:container, kind, picked)
endfunction
