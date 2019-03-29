
" PHP {{{1
let s:types = {}

let s:types.lang = 'php'

let s:types.kinds = {
    \ 'n': {'long' : 'namespaces',           'fold' : 0, 'stl' : 0},
    \ 'a': {'long' : 'use aliases',          'fold' : 1, 'stl' : 0},
    \ 'd': {'long' : 'constant definitions', 'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'interfaces',           'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'traits',               'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'classes',              'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',            'fold' : 1, 'stl' : 0},
    \ 'f': {'long' : 'functions',            'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '\\'

let s:types.kind2scope = {
    \ 'c' : 'class',
    \ 'n' : 'namespace',
    \ 'i' : 'interface',
    \ 't' : 'trait',
    \ }

let s:types.scope2kind = {
    \ 'class'     : 'c',
    \ 'namespace' : 'n',
    \ 'interface' : 'i',
    \ 'trait'     : 't',
    \ }

let g:vista#types#uctags#php# = s:types
