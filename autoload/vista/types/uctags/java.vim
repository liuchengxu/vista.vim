
" Java {{{1
let s:types = {}

let s:types.lang = 'java'

let s:types.kinds = {
    \ 'p': {'long' : 'packages',       'fold' : 1, 'stl' : 0},
    \ 'f': {'long' : 'fields',         'fold' : 0, 'stl' : 0},
    \ 'g': {'long' : 'enum types',     'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enum constants', 'fold' : 0, 'stl' : 0},
    \ 'a': {'long' : 'annotations',    'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'interfaces',     'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'classes',        'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'methods',        'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '.'

let s:types.kind2scope = {
    \ 'g' : 'enum',
    \ 'i' : 'interface',
    \ 'c' : 'class'
    \ }

let s:types.scope2kind = {
    \ 'enum'      : 'g',
    \ 'interface' : 'i',
    \ 'class'     : 'c'
    \ }

let g:vista#types#uctags#java# = s:types
