scriptencoding utf-8

function! SetUp()
  runtime plugin/vista.vim
  let g:vista#renderer#icon = 0
endfunction

function! s:GetLines()
  return getbufline(winbufnr(t:vista.winnr()), 1, '$')
endfunction

function! Test_Disable_Icon()
  call assert_equal(g:vista#renderer#icon, 0)
endfunction

function! Test_Vista_ctags_Should_Work()
  execute 'edit' expand('./data/70.py')

  Vista! ctags

  let vista_lines = s:GetLines()
  echom "LINES:".string(vista_lines)
  let expected = [
        \ '../vista.vim/test/data/70.py',
        \ '',
        \ '+Foo :  class:1',
        \ '    +Bar :  class:2',
        \ '        +baz(self) :  member:3',
        \ ]
  call assert_equal(expected, vista_lines)
  %bwipeout!
endfunction

function! Test_Vista_Should_Work()
  execute 'edit' expand('./data/114.py')

  Vista!

  sleep 1000m

  let vista_lines = s:GetLines()
  let expected = [
        \ '..m/plugged/vista.vim/test/data/114.py',
        \ '',
        \ '+Foo :  class:1',
        \ '+__init__(self, x) :  member:2',
        \ ]
  call assert_equal(vista_lines, expected)
endfunction
