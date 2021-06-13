" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:last_req_id = 0

function! s:HandleLSPResponse(_server, _req_id, _type, data) abort
  let s:fetching = v:false
  if !has_key(a:data.response, 'result')
    return []
  endif

  let result = a:data.response.result

  let s:data = vista#renderer#LSPPreprocess(result)

  if !empty(s:data)
    let s:ever_done = v:true
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
  if s:HasAvaliableServers()
    call s:RunAsync()
  endif
endfunction

function! s:HasAvaliableServers() abort
  if !exists('*lsp#get_whitelisted_servers')
    return 0
  endif
  let s:servers = filter(lsp#get_whitelisted_servers(),
        \ 'lsp#capabilities#has_document_symbol_provider(v:val)')
  return len(s:servers)
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
  for server in s:servers
    call lsp#send_request(server, {
        \ 'method': 'textDocument/documentSymbol',
        \ 'params': {
        \   'textDocument': lsp#get_text_document_identifier(),
        \ },
        \ 'on_notification': function('s:HandleLSPResponse', [server, s:last_req_id, 'documentSymbol']),
        \ })
    let s:fetching = v:true
  endfor
endfunction

function! vista#executive#vim_lsp#Run(fpath) abort
  if s:HasAvaliableServers()
    let s:fpath = a:fpath
    return s:Run()
  endif
endfunction

function! vista#executive#vim_lsp#RunAsync() abort
  if s:HasAvaliableServers()
    call s:RunAsync()
  endif
endfunction

function! vista#executive#vim_lsp#Execute(bang, should_display, ...) abort
  if !s:HasAvaliableServers()
    if get(a:000, 0, v:true)
      return vista#error#('Retrieving symbols is not avaliable')
    endif
    return
  endif

  call vista#source#Update(bufnr('%'), winnr(), expand('%'), expand('%:p'))
  let s:fpath = expand('%:p')

  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let g:vista.silent = v:false
  let s:should_display = a:should_display

  if a:bang
    call s:Run()
  else
    if !exists('s:ever_done')
      call vista#util#Retriving(s:provider)
    endif
    call s:RunAsync()
  endif
endfunction

function! vista#executive#vim_lsp#Cache() abort
  return get(s:, 'cache', {})
endfunction
