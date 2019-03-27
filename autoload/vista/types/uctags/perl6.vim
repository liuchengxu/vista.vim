
" Perl 6 {{{1
let s:types6 = {}

let s:types6.lang = 'perl6'

let s:types6.kinds = {
    \ 'o': {'long' : 'modules',     'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'packages',    'fold' : 1, 'stl' : 0},
    \ 'c': {'long' : 'classes',     'fold' : 0, 'stl' : 1},
    \ 'g': {'long' : 'grammars',    'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'methods',     'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'roles',       'fold' : 0, 'stl' : 1},
    \ 'u': {'long' : 'rules',       'fold' : 0, 'stl' : 0},
    \ 'b': {'long' : 'submethods',  'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'subroutines', 'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'tokens',      'fold' : 0, 'stl' : 0},
    \ }

let g:vista#types#uctags#perl6# = s:types6
