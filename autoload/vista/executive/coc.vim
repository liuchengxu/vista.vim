" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

" Extract fruitful infomation from raw symbols
function! s:Extract(symbols) abort
  if empty(a:symbols)
    return
  endif

  let s:data = {}
  let t:vista.functions = []
  call map(a:symbols, 'vista#parser#lsp#ExtractSymbol(v:val, s:data)')

  if empty(s:data)
    return
  endif

  let s:cache = get(s:, 'cache', {})
  let s:cache.data = s:data
  let s:cache.bufnr = bufnr('')

  if s:reload_only
    call vista#sidebar#Reload(s:data)
    let s:reload_only = v:false
    return
  endif

  if s:should_display
    call vista#viewer#Display(s:data)
    let s:should_display = v:false
  endif

  return s:data
endfunction

function! s:Cb(error, response) abort
  if empty(a:error)
    " Refer to coc.nvim 79cb11e
    " No document symbol provider exists when response is null.
    if a:response is# v:null
      return
    endif
    call s:Extract(a:response)
  else
    call vista#error#("Error when calling CocActionAsync('documentSymbols')")
  endif
endfunction

function! s:AutoUpdate(_fpath) abort
  let s:reload_only = v:true
  call CocActionAsync('documentSymbols', function('s:Cb'))
endfunction

function! s:Run() abort
  return s:Extract(CocAction('documentSymbols'))
endfunction

function! s:RunAsync() abort
  call CocActionAsync('documentSymbols', function('s:Cb'))
endfunction

function! s:Execute(bang, should_display) abort
  call vista#source#Update(bufnr('%'), winnr(), expand('%'), expand('%:p'))

  if a:bang
    call s:Extract(CocAction('documentSymbols'))
    if a:should_display
      call vista#viewer#Display(s:data)
    endif
  else
    let s:should_display = a:should_display
    call CocActionAsync('documentSymbols', function('s:Cb'))
  endif
endfunction

function! s:Dispatch(F, ...) abort
  if !exists('*CocActionAsync')
    call vista#error#Need('coc.nvim')
    return
  endif

  return call(function(a:F), a:000)
endfunction

function! vista#executive#coc#Cache() abort
  return get(s:, 'cache', {})
endfunction

" Internal public APIs
"
" Run and RunAsync is for internal use.
function! vista#executive#coc#Run(_fpath) abort
  if exists('*CocAction')
    return s:Run()
  endif
endfunction

function! vista#executive#coc#RunAsync() abort
  call s:Dispatch('s:RunAsync')
endfunction

function! vista#executive#coc#Execute(bang, should_display, ...) abort
  call vista#SetProvider(s:provider)
  call vista#autocmd#Init('VistaCoc', function('s:AutoUpdate'))
  return s:Dispatch('s:Execute', a:bang, a:should_display)
endfunction
