" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

function! s:Handler(data) abort
  if type(a:data) != v:t_dict
        \ || has_key(a:data, 'error')
        \ || !has_key(a:data, 'result')
        \ || empty(get(a:data, 'result', {}))
    let s:fetching = v:false
    return
  endif

  let lines = []
  call map(a:data.result, 'vista#parser#lsp#KindToSymbol(v:val, lines)')

  let s:data = {}
  let t:vista.functions = []
  call map(lines, 'vista#parser#lsp#ExtractSymbol(v:val, s:data)')

  let s:fetching = v:false

  if !empty(s:data)
    if s:reload_only
      call vista#sidebar#Reload(s:data)
      let s:reload_only = v:false
      return
    endif

    if s:should_display
      let t:vista.tmp = s:data
      call vista#viewer#Display(s:data)
      let s:should_display = v:false
    endif
  endif
endfunction

function! s:AutoUpdate(fpath) abort
  let s:reload_only = v:true
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
  let method = 'textDocument/documentSymbol'
  let bufnr = bufnr('')
  let params = {
    \   'textDocument': {
    \       'uri': ale#path#ToURI(expand('#' . bufnr . ':p')),
    \   }
    \}
  let message = [0, method, params]
  let Callback = function('s:Handler')

  let linters = map(filter(ale#linter#Get(&filetype), '!empty(v:val.lsp)'), 'v:val.name')

  if empty(linters)
    return
  endif

  for linter in linters
    call ale#lsp_linter#SendRequest(bufnr, linter, message, Callback)
    let s:fetching = v:true
  endfor
endfunction

function! vista#executive#ale#Cache() abort
  return get(s:, 'data', {})
endfunction

function! vista#executive#ale#Run(fpath) abort
  return s:Run()
endfunction

function! vista#executive#ale#RunAsync() abort
  call s:RunAsync()
endfunction

function! vista#executive#ale#Execute(bang, should_display, ...) abort
  let s:should_display = a:should_display

  call vista#OnExecute(s:provider, function('s:AutoUpdate'))
  if a:bang
    call s:Run()
  else
    call s:RunAsync()
  endif
endfunction
