
" Go {{{1
let type_go = {}

let type_go.lang = 'go'

let type_go.kinds = {
    \ 'p': {'long' : 'packages',       'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'imports',        'fold' : 0, 'stl' : 0},
    \ 'n': {'long' : 'interfaces',     'fold' : 0, 'stl' : 0},
    \ 'c': {'long' : 'constants',      'fold' : 0, 'stl' : 0},
    \ 's': {'long' : 'structs',        'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'methods',        'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'types',          'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',      'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',      'fold' : 0, 'stl' : 0},
    \ 'w': {'long' : 'struct members', 'fold' : 0, 'stl' : 0}
    \ }

let type_go.sro = '.'

let type_go.kind2scope = {
    \ 's' : 'struct'
    \ }

let type_go.scope2kind = {
    \ 'struct' : 's'
    \ }

let g:vista#types#uctags#go# = type_go
