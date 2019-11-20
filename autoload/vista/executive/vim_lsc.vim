" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:fetching = v:true

function! s:Handler(results) abort
  if empty(a:results)
    let s:fetching = v:false
    return []
  endif


  let lines = []
  call map(a:results, 'vista#parser#lsp#KindToSymbol(v:val, lines)')

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
      call vista#renderer#RenderAndDisplay(s:data)
      let s:should_display = v:false
    endif
  endif
endfunction

function! s:AutoUpdate(fpath) abort
  let s:reload_only = v:true
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
        \ function('s:Handler'))
  endif
endfunction

function! vista#executive#vim_lsc#Run(_fpath) abort
  return s:Run()
endfunction

function! vista#executive#vim_lsc#RunAsync() abort
  call s:RunAsync()
endfunction

function! vista#executive#vim_lsc#Execute(bang, should_display, ...) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let t:vista.silent = v:false
  let s:should_display = a:should_display

  if a:bang
    return s:Run()
  else
    call s:RunAsync()
  endif
endfunction

function! vista#executive#vim_lsc#Cache() abort
  return get(s:, 'data', {})
endfunction
