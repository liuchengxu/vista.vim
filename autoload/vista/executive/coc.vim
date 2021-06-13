" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

" Extract fruitful infomation from raw symbols
function! s:DoHandleResponse(symbols) abort
  let s:data = []

  if empty(a:symbols)
    return
  endif

  let g:vista.functions = []
  let g:vista.raw = []
  call map(a:symbols, 'vista#parser#lsp#CocSymbols(v:val, s:data)')

  if !empty(s:data)
    let [s:reload_only, s:should_display] = vista#renderer#LSPProcess(s:data, s:reload_only, s:should_display)

    " Update cache when new data comes.
    let s:cache = get(s:, 'cache', {})
    let s:cache[s:fpath] = s:data
    let s:cache.ftime = getftime(s:fpath)
    let s:cache.bufnr = bufnr('')
  endif

  return s:data
endfunction

" Deprecated as a lot of people complain the error message.
function! s:HandleLSPResponse(error, response) abort
  if empty(a:error)
    " Refer to coc.nvim 79cb11e
    " No document symbol provider exists when response is null.
    if a:response isnot v:null
      call s:DoHandleResponse(a:response)
      call vista#cursor#TryInitialRun()
    endif
  else
    call vista#error#Notify("Error when calling CocActionAsync('documentSymbols'): ".string(a:error))
  endif
endfunction

function! s:HandleLSPResponseInSilence(error, response) abort
  if empty(a:error) && a:response isnot v:null
    call s:DoHandleResponse(a:response)
  endif
endfunction

function! s:AutoUpdate(_fpath) abort
  let s:reload_only = v:true
  call vista#AutoUpdateWithDelay(function('CocActionAsync'), ['documentSymbols', function('s:HandleLSPResponseInSilence')])
endfunction

function! s:Run() abort
  return s:DoHandleResponse(CocAction('documentSymbols'))
endfunction

function! s:RunAsync() abort
  call CocActionAsync('documentSymbols', function('s:HandleLSPResponseInSilence'))
endfunction

function! s:Execute(bang, should_display) abort
  call vista#source#Update(bufnr('%'), winnr(), expand('%'), expand('%:p'))
  let s:fpath = expand('%:p')

  if a:bang
    call s:DoHandleResponse(CocAction('documentSymbols'))
    if a:should_display
      call vista#renderer#RenderAndDisplay(s:data)
    endif
  else
    let s:should_display = a:should_display
    call s:RunAsync()
  endif
endfunction

function! s:Dispatch(F, ...) abort
  if !exists('*CocActionAsync')
    call vista#error#Need('coc.nvim')
    return
  endif

  call vista#SetProvider(s:provider)
  return call(function(a:F), a:000)
endfunction

function! vista#executive#coc#Cache() abort
  return get(s:, 'cache', {})
endfunction

" Internal public APIs
"
" Run and RunAsync is for internal use.
function! vista#executive#coc#Run(fpath) abort
  if exists('*CocAction')
    call vista#SetProvider(s:provider)
    let s:fpath = a:fpath
    call vista#win#Execute(g:vista.source.get_winnr(), function('s:Run'))
    return s:data
  endif
endfunction

function! vista#executive#coc#RunAsync() abort
  call s:Dispatch('s:RunAsync')
endfunction

" The public Execute function is used for interacting with this plugin from
" outside, where sets the provider and auto update events.
function! vista#executive#coc#Execute(bang, should_display, ...) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))
  let g:vista.silent = v:false
  return s:Dispatch('s:Execute', a:bang, a:should_display)
endfunction
