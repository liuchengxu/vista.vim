" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:Echom(group, msg) abort
  execute 'echohl' a:group
  echom a:msg
  echohl NONE
endfunction

function! s:Echon(group, msg) abort
  execute 'echohl' a:group
  echon a:msg
  echohl NONE
endfunction

function! vista#error#Expect(expected) abort
  call s:Echom('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' Invalid args. expected: ')
  call s:Echon('Underlined', a:expected)
endfunction

function! vista#error#Need(needed) abort
  call s:Echom('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' You must have ')
  call s:Echon('Underlined', a:needed)
  call s:Echon('Normal', ' installed to continue.')
endfunction

function! vista#error#InvalidExecutive(exe) abort
  call s:Echom('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' The executive')
  call s:Echon('Underlined', ' '.a:exe.' ')
  call s:Echon('Normal', 'does not exist. Avaliable: ')
  call s:Echon('Underlined', string(g:vista#executives))
endfunction

function! vista#error#ParseError() abort
endfunction

function! vista#error#(msg) abort
  call s:Echom('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', a:msg)
endfunction
