let s:symbol_kinds = {
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
    \ }

function! s:Kind2SymbolText(kind) abort
  return has_key(s:symbol_kinds, a:kind) ? s:symbol_kinds[a:kind] : 'Unknown kind '.a:kind
endfunction

function! s:IsFileUri(uri) abort
  return stridx(a:uri, 'file:///') == 0
endfunction

function s:Handler(output) abort
  if !has_key(a:output, 'result')
    echom "No result"
    return
  endif

  let result = a:output.result

  let lists = []

  for symbol in result
    let location = symbol.location
    if s:IsFileUri(location.uri)
      let lnum = location.range.start.line + 1
      let col = location.range.start.character + 1
      call add(l:lists, {
          \ 'lnum': lnum,
          \ 'col': col,
          \ 'kind': s:Kind2SymbolText(l:symbol['kind']),
          \ 'text': symbol.name,
          \ })
    endif
  endfor

  let s:data = {}

  for line in lists
    let picked = {'lnum': line.lnum, 'text': line.text}
    let kind = line.kind

    if has_key(s:data, kind)
      call add(s:data[kind], picked)
    else
      let s:data[kind] = [picked]
    endif
  endfor

  call vista#viewer#Display(s:data)
endfunction

function! vista#executive#lcn#Run(_fpath) abort
  call LanguageClient#textDocument_documentSymbol({'handle': v:false}, function('s:Handler'))
endfunction

function! vista#executive#lcn#RunAsync() abort
  call LanguageClient#textDocument_documentSymbol({'handle': v:false}, function('s:Handler'))
endfunction

function! vista#executive#lcn#Execute(bang, should_display) abort
  let t:vista.provider = 'lcn'
  call LanguageClient#textDocument_documentSymbol({'handle': v:false}, function('s:Handler'))
endfunction
