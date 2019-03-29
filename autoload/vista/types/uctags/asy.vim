" Asymptote {{{1
" Asymptote gets parsed well using filetype = c
let s:types = {}

let s:types.lang = 'c'

let s:types.kinds = {
    \ 'd': {'long' : 'macros',      'fold' : 1, 'stl' : 0},
    \ 'p': {'long' : 'prototypes',  'fold' : 1, 'stl' : 0},
    \ 'g': {'long' : 'enums',       'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enumerators', 'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'typedefs',    'fold' : 0, 'stl' : 0},
    \ 's': {'long' : 'structs',     'fold' : 0, 'stl' : 1},
    \ 'u': {'long' : 'unions',      'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'members',     'fold' : 0, 'stl' : 0},
    \ 'v': {'long' : 'variables',   'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'functions',   'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '::'

let s:types.kind2scope = {
    \ 'g' : 'enum',
    \ 's' : 'struct',
    \ 'u' : 'union'
    \ }

let s:types.scope2kind = {
    \ 'enum'   : 'g',
    \ 'struct' : 's',
    \ 'union'  : 'u'
    \ }

let g:vista#types#uctags#asy# = s:types
