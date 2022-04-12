" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

function! s:HandleLSPResponse(resp) abort
  let s:fetching = v:false
  if type(a:resp) != v:t_dict
        \ || has_key(a:resp, 'error')
        \ || !has_key(a:resp, 'result')
        \ || empty(get(a:resp, 'result', {}))
    return
  endif

  let s:data = vista#renderer#LSPPreprocess(a:resp.result)

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
  let s:fetching = v:false
  call s:RunAsync()
  while s:fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! s:RunAsync() abort
  let linters = map(filter(ale#linter#Get(&filetype), '!empty(v:val.lsp)'), 'v:val.name')
  if empty(linters)
    return
  endif

  let method = 'textDocument/documentSymbol'
  let bufnr = g:vista.source.bufnr
  let params = {
    \   'textDocument': {
    \       'uri': ale#path#ToFileURI(expand('#' . bufnr . ':p')),
    \   }
    \}
  let message = [0, method, params]
  let Callback = function('s:HandleLSPResponse')

  for linter in linters
    call ale#lsp_linter#SendRequest(bufnr, linter, message, Callback)
    let s:fetching = v:true
  endfor
endfunction

function! vista#executive#ale#Run(fpath) abort
  if exists('g:loaded_ale_dont_use_this_in_other_plugins_please')
    let s:fpath = a:fpath
    return s:Run()
  endif
endfunction

function! vista#executive#ale#RunAsync() abort
  if exists('g:loaded_ale_dont_use_this_in_other_plugins_please')
    call s:RunAsync()
  endif
endfunction

function! vista#executive#ale#Execute(bang, should_display, ...) abort
  call vista#source#Update(bufnr('%'), winnr(), expand('%'), expand('%:p'))
  let s:fpath = expand('%:p')

  let g:vista.silent = v:false
  let s:should_display = a:should_display

  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  if a:bang
    call s:Run()
  else
    call s:RunAsync()
  endif
endfunction

function! vista#executive#ale#Cache() abort
  return get(s:, 'cache', {})
endfunction
