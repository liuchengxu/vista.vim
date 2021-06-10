" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:fetching = v:true

function! s:HandleLSPResponse(results) abort
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
  if !exists('*lsc#server#userCall')
    return
  endif
  call s:RunAsync()
  while s:fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! s:RunAsync() abort
  if exists('*lsc#server#userCall')
    call vista#SetProvider(s:provider)

    " vim-lsc
    call lsc#file#flushChanges()
    call lsc#server#userCall('textDocument/documentSymbol',
        \ lsc#params#textDocument(),
        \ function('s:HandleLSPResponse'))
  endif
endfunction

function! vista#executive#vim_lsc#Run(fpath) abort
  let s:fpath = a:fpath
  return s:Run()
endfunction

function! vista#executive#vim_lsc#RunAsync() abort
  call s:RunAsync()
endfunction

function! vista#executive#vim_lsc#Execute(bang, should_display, ...) abort
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

function! vista#executive#vim_lsc#Cache() abort
  return get(s:, 'cache', {})
endfunction
