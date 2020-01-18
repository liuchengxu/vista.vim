scriptencoding utf-8

function! SetUp()
  runtime plugin/vista.vim
endfunction

function! Test_Vista_Should_Work()
  execute 'edit' expand('./data/70.py')

  Vista ctags

  sleep 200m

  let vista_lines = getbufline(winbufnr(t:vista.winnr()), 1, '$')
  let expected = [
        \ '../vista.vim/test/data/70.py',
        \ '',
        \ '+Foo :  class:1',
        \ '    +Bar :  class:2',
        \ '        +baz(self) :  member:3',
        \ ]
  call assert_equal(vista_lines, expected)
endfunction
