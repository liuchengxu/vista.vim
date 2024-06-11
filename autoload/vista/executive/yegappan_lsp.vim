" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:fetching = v:true

function! s:HandleLSPResponse(server, results) abort
  let s:fetching = v:false
  if empty(a:results)
    return []
  endif

  let s:data = vista#renderer#LSPPreprocess(a:results)

  if !empty(s:data)
    let [s:reload_only, s:should_display] = vista#renderer#LSPProcess(s:data, s:reload_only, s:should_display)

    " Update cache when new data comes.
    let s:cache = get(s:, 'cache', {})
    let s:cache[s:fpath] = s:data
    let s:cache.ftime = getftime(s:fpath)
    let s:cache.bufnr = bufnr('')
  endif

  call vista#cursor#TryInitialRun()
endfunction

function! s:AutoUpdate(fpath) abort
  let s:reload_only = v:true
  let s:fpath = a:fpath
  call s:RunAsync()
endfunction

function! s:Run() abort
  call s:RunAsync()
  while s:fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! s:RunAsync() abort
  call vista#SetProvider(s:provider)

  let bufnum = bufnr('%')
  let params = #{textDocument: #{uri: lsp#util#LspFileToUri(bufname(bufnum))}}
  let servers = lsp#buffer#BufLspServersGet(bufnum)

  for server in servers
    if !server.isDocumentSymbolProvider
        continue
    endif

    silent call server.rpc_a('textDocument/documentSymbol', params, function('s:HandleLSPResponse'))
  endfor
endfunction

function! vista#executive#yegappan_lsp#Run(fpath) abort
  let s:fpath = a:fpath
  return s:Run()
endfunction

function! vista#executive#yegappan_lsp#RunAsync() abort
  call s:RunAsync()
endfunction

function! vista#executive#yegappan_lsp#Execute(bang, should_display, ...) abort
  call vista#source#Update(bufnr('%'), winnr(), expand('%'), expand('%:p'))
  let s:fpath = expand('%:p')

  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let g:vista.silent = v:false
  let s:should_display = a:should_display

  if a:bang
    return s:Run()
  else
    call s:RunAsync()
  endif
endfunction

function! vista#executive#yegappan_lsp#Cache() abort
  return get(s:, 'cache', {})
endfunction
