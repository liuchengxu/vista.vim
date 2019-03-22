" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(resolve(expand('<sfile>')), ':t:r')

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
  call map(result, 'vista#parser#lsp#FromKindToSymbol(v:val, lines)')

  let s:data = {}
  call map(lines, 'vista#parser#lsp#ExtractSymbol(v:val, s:data)')

  let s:fetching = v:false

  if s:reload_only
    call vista#sidebar#Reload(s:data)
    let s:reload_only = v:false
    return
  endif

  if s:should_display
    call vista#viewer#Display(s:data)
    let s:should_display = v:false
  endif
endfunction

function! s:AutoUpdate(fpath) abort
  let s:reload_only = v:true
  let servers = s:AvaliableServers()
  if len(servers) > 0
    call s:RunAsync(servers)
  endif
endfunction

function! s:AvaliableServers() abort
  return filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_document_symbol_provider(v:val)')
endfunction

function! s:Run(servers) abort
  call s:RunAsync(a:servers)
  while s:fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! s:RunAsync(servers) abort
  for server in a:servers
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
  let servers = s:AvaliableServers()
  if len(servers) > 0
    return s:Run(servers)
  endif
endfunction

function! vista#executive#vim_lsp#RunAsync() abort
  let servers = s:AvaliableServers()
  if len(servers) > 0
    call s:RunAsync(servers)
  endif
endfunction

function! vista#executive#vim_lsp#Execute(bang, should_display) abort
  let servers = s:AvaliableServers()

  if len(servers) == 0
    return vista#error#("Retrieving symbols is not avaliable")
  endif

  let s:should_display = a:should_display
  call vista#SetProvider(s:provider)
  call vista#autocmd#Init('VistaVimLsp', function('s:AutoUpdate'))
  if a:bang
    call s:Run(servers)
  else
    call s:RunAsync(servers)
  endif
endfunction

function! vista#executive#vim_lsp#Cache() abort
  return get(s:, 'data', {})
endfunction
