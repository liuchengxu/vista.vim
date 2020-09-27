" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:LoadData(container, line) abort
  let line = a:line

  let kind = line.kind

  call vista#util#TryAdd(g:vista.raw_by_kind, kind, line)

  call add(g:vista.raw, line)

  if has_key(line, 'scope')
    call add(g:vista.with_scope, line)
  else
    call add(g:vista.without_scope, line)
  endif

  let picked = {'lnum': line.line, 'text': get(line, 'name', '') }

  if kind =~# '^f' || kind =~# '^m'
    if has_key(line, 'signature')
      let picked.signature = line.signature
    endif
    call add(g:vista.functions, picked)
  endif

  if index(g:vista.kinds, kind) == -1
    call add(g:vista.kinds, kind)
  endif

  call vista#util#TryAdd(a:container, kind, picked)
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
  let ft = getbufvar(g:vista.source.bufnr, '&filetype')

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
    let value = a:tagfields[0][colon+1:]
    let fields.kind = value
  else
    let kind = s:ShortToLong(a:tagfields[0])
    let fields.kind = kind
    if index(g:vista.kinds, kind) == -1
      call add(g:vista.kinds, kind)
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
  " Prevent bugs when a:line is all whitespace or doesn't contain any tabs
  " (can't be parsed).
  if a:line =~# '^\s*$' || stridx(a:line, "\t") == -1
    " Useful for debugging
    " echom "Vista.vim: Error parsing ctags output: '" . a:line . "'"
    return
  endif

  let items = split(a:line, '\t')

  let line = {}

  let line.name = items[0]
  let line.tagfile = items[1]

  " tagaddress itself possibly contains <Tab>, so we have to restore the
  " original content and then split by `;"` to get the tagaddress and other
  " fields.
  " tagaddress may also contains `;"`, so we join all the splits except the
  " last one as the tagaddress and keep the last split as the other fields.
  let rejoined = join(items[2:], "\t")
  let resplitted = split(rejoined, ';"')
  let splits = len(resplitted)
  let line.tagaddress = join(resplitted[:splits-2], ';"')

  let fields = split(resplitted[splits-1], '\t')
  let tagfields = s:ParseTagfield(fields)

  call extend(line, tagfields)

  if vista#ShouldIgnore(line.kind)
    return
  endif

  call s:LoadData(a:container, line)

endfunction

function! vista#parser#ctags#FromJSON(line, container) abort
  if a:line =~# '^ctags'
    return
  endif

  try
    let line = json_decode(a:line)
  catch
    call vista#error#('Fail to decode from JSON: '.a:line.', error: '.v:exception)
    return
  endtry

  if vista#ShouldIgnore(line.kind)
    return
  endif

  call s:LoadData(a:container, line)

endfunction

" ctags -R -x --_xformat='TAGNAME:%N ++++ KIND:%K ++++ LINE:%n ++++ INPUT-FILE:%F ++++ PATTERN:%P'"
"
function! vista#parser#ctags#RecursiveFromXformat(line, container) abort

  if a:line =~# '^ctags: Warning:'
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
  if vista#ShouldIgnore(kind)
    return
  endif
  " LINE:
  let lnum = items[2][5:]
  " INPUT-FILE:
  let relpath = items[3][11:]
  " PATTERN:
  let pattern = items[4][8:]

  let picked = {'lnum': lnum, 'text': tagname, 'tagfile': relpath, 'taginfo': pattern[2:-3]}

  call vista#util#TryAdd(a:container, kind, picked)
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

  if vista#ShouldIgnore(kind)
    return
  endif

  let picked = {'lnum': line.line, 'text': line.name, 'tagfile': line.path, 'taginfo': line.pattern[2:-3]}

  call vista#util#TryAdd(a:container, kind, picked)
endfunction
