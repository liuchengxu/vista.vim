" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:fetching = v:true

function! s:Handler(output) abort
  if !has_key(a:output, 'result')
    call vista#error#('No result via LanguageClient#textDocument_documentSymbol()')
    let s:fetching = v:false
    return
  endif

  let result = a:output.result

  let lines = []
  call map(result, 'vista#parser#lsp#KindToSymbol(v:val, lines)')

  let s:data = {}
  let t:vista.functions = []
  call map(lines, 'vista#parser#lsp#ExtractSymbol(v:val, s:data)')

  let s:fetching = v:false

  if s:reload_only
    call vista#sidebar#Reload(s:data)
    let s:reload_only = v:false
    return
  endif

  if s:should_display
    let s:should_display = v:false
    call vista#viewer#Display(s:data)
  endif
endfunction

function! s:AutoUpdate(fpath) abort
  let s:reload_only = v:true
  call s:RunAsync()
endfunction

function! s:Run() abort
  call s:RunAsync()
  let s:fetching = v:true
  while s:fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! s:RunAsync() abort
  call LanguageClient#textDocument_documentSymbol(
        \ {'handle': v:false}, function('s:Handler'))
endfunction

function! vista#executive#lcn#Run(_fpath) abort
  if exists('*LanguageClient#textDocument_documentSymbol')
    return s:Run()
  endif
endfunction

function! vista#executive#lcn#RunAsync() abort
  if exists('*LanguageClient#textDocument_documentSymbol')
    call s:RunAsync()
  endif
endfunction

function! vista#executive#lcn#Execute(bang, should_display, ...) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let s:should_display = a:should_display
  if a:bang
    return s:Run()
  else
    call s:RunAsync()
  endif
endfunction

function! vista#executive#lcn#Cache() abort
  return get(s:, 'data', {})
endfunction
