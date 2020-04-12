" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:has_floating_win = exists('*nvim_open_win')
let s:has_popup = exists('*popup_create')

function! vista#win#CloseFloating() abort
  if s:has_floating_win
    call vista#floating#Close()
  elseif s:has_popup
    call vista#popup#Close()
  endif
endfunction

function! vista#win#FloatingDisplay(...) abort
  if s:has_popup
    call call('vista#popup#DisplayAt', a:000)
  elseif s:has_floating_win
    call call('vista#floating#DisplayAt', a:000)
  else
    call vista#error#Need('neovim compiled with floating window support or vim compiled with popup feature')
  endif
endfunction

" Show the folded content if in a closed fold.
function! vista#win#ShowFoldedDetailInFloatingIsOk() abort
  if foldclosed('.') != -1
    if s:has_floating_win || s:has_popup
      let foldclosed_end = foldclosedend('.')
      let curlnum = line('.')
      let lines = getbufline(g:vista.bufnr, curlnum, foldclosed_end)

      if s:has_floating_win
        call vista#floating#DisplayRawAt(curlnum, lines)
      elseif s:has_popup
        call vista#popup#DisplayRawAt(curlnum, lines)
      endif

      return v:true
    endif
  endif
  return v:false
endfunction

function! vista#win#FloatingDisplayOrPeek(lnum, tag) abort
  if s:has_floating_win || s:has_popup
    call vista#win#FloatingDisplay(a:lnum, a:tag)
  else
    call vista#source#PeekSymbol(a:lnum, a:tag)
  endif
endfunction

" call Run in the window win unsilently, unlike win_execute() which uses
" silent by default.
"
" CocAction only fetch symbols for current document, no way for specify the other at the moment.
" workaround for #52
"
" see also #71
"
" NOTE: a:winnr is winnr, not winid. Ref https://github.com/liuchengxu/vim-clap/issues/371
function! vista#win#Execute(winnr, Run, ...) abort
  if winnr() != a:winnr
    noautocmd execute a:winnr.'wincmd w'
    let l:switch_back = 1
  endif

  call call(a:Run, a:000)

  if exists('l:switch_back')
    noautocmd wincmd p
  endif
endfunction
