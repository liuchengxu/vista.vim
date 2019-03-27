
" Protobuf {{{1
let s:types = {}

let s:types.lang = 'Protobuf'

let s:types.kinds = {
    \ 'p': {'long' : 'packages',       'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'messages',       'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'fields',         'fold' : 0, 'stl' : 0},
    \ 'e': {'long' : 'enum constants', 'fold' : 0, 'stl' : 0},
    \ 'g': {'long' : 'enum types',     'fold' : 0, 'stl' : 0},
    \ 's': {'long' : 'services',       'fold' : 0, 'stl' : 0},
    \ }

let g:vista#types#uctags#proto# = s:types
