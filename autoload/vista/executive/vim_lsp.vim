" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:last_req_id = 0

function! s:Handler(_server, _req_id, _type, data) abort
  if !has_key(a:data.response, 'result')
    let s:fetching = v:false
    return []
  endif

  let result = a:data.response.result

  let lines = []
  call map(result, 'vista#parser#lsp#KindToSymbol(v:val, lines)')

  let s:data = {}
  let t:vista.functions = []
  call map(lines, 'vista#parser#lsp#ExtractSymbol(v:val, s:data)')

  let s:fetching = v:false

  if !empty(s:data)
    let s:ever_done = v:true
    if s:reload_only
      call vista#sidebar#Reload(s:data)
      let s:reload_only = v:false
      return
    endif

    if s:should_display
      call vista#viewer#Display(s:data)
      let s:should_display = v:false
    endif
  endif
endfunction

function! s:AutoUpdate(fpath) abort
  let s:reload_only = v:true
  if s:HasAvaliableServers()
    call s:RunAsync()
  endif
endfunction

function! s:HasAvaliableServers() abort
  if !exists('*lsp#get_whitelisted_servers')
    return 0
  endif
  let s:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_document_symbol_provider(v:val)')
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
  for server in s:servers
    call lsp#send_request(server, {
        \ 'method': 'textDocument/documentSymbol',
        \ 'params': {
        \   'textDocument': lsp#get_text_document_identifier(),
        \ },
        \ 'on_notification': function('s:Handler', [server, s:last_req_id, 'documentSymbol']),
        \ })
    let s:fetching = v:true
  endfor
endfunction

function! vista#executive#vim_lsp#Run(_fpath) abort
  if s:HasAvaliableServers()
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

  let s:should_display = a:should_display

  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

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
  return get(s:, 'data', {})
endfunction
