" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:Echo(group, msg) abort
  execute 'echohl' a:group
  echo a:msg
  echohl NONE
endfunction

function! s:Echon(group, msg) abort
  execute 'echohl' a:group
  echon a:msg
  echohl NONE
endfunction

function! vista#error#Expect(expected) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' Invalid args. expected: ')
  call s:Echon('Underlined', a:expected)
endfunction

function! vista#error#Need(needed) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' You must have ')
  call s:Echon('Underlined', a:needed)
  call s:Echon('Normal', ' installed to continue.')
endfunction

function! vista#error#RunCtags(cmd) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', 'Fail to run ctags given the command: ')
  call s:Echon('Underlined', a:cmd)
endfunction

function! vista#error#For(cmd, filetype) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Underlined', ' '.a:cmd)
  call s:Echon('Normal', ' does not support '.a:filetype.' filetype.')
endfunction

function! vista#error#InvalidExecutive(exe) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' The executive')
  call s:Echon('Underlined', ' '.a:exe.' ')
  call s:Echon('Normal', 'does not exist. Avaliable: ')
  call s:Echon('Underlined', string(g:vista#executives))
endfunction

function! vista#error#InvalidOption(opt, ...) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' Invalid option '.a:opt.'. Avaliable: ')
  call s:Echon('Underlined', a:0 > 0 ? string(a:1) : '')
endfunction

function! vista#error#InvalidFinderArgument() abort
  call vista#error#Expect('Vista finder [FINDER|EXECUTIVE|FINDER:EXECUTIVE]')
endfunction

" Notify the error message when required.
function! vista#error#Notify(msg) abort
  if !get(g:vista, 'silent', v:true)
    call vista#error#(a:msg)
    let g:vista.silent = v:true
  endif
endfunction

function! vista#error#(msg) abort
  call s:Echo('ErrorMsg', '[vista.vim]')
  call s:Echon('Normal', ' '.a:msg)
endfunction
