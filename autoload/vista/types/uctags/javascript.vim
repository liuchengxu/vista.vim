
" JavaScript {{{1
let s:types = {}

let s:types.lang = 'javascript'

let s:types.kinds = {
    \ 'v': {'long': 'global variables', 'fold': 0, 'stl': 0},
    \ 'C': {'long': 'constants',        'fold': 0, 'stl': 0},
    \ 'c': {'long': 'classes',          'fold': 0, 'stl': 1},
    \ 'g': {'long': 'generators',       'fold': 0, 'stl': 0},
    \ 'p': {'long': 'properties',       'fold': 0, 'stl': 0},
    \ 'm': {'long': 'methods',          'fold': 0, 'stl': 1},
    \ 'f': {'long': 'functions',        'fold': 0, 'stl': 1},
    \ }

let s:types.sro        = '.'

let s:types.kind2scope = {
    \ 'c' : 'class',
    \ 'f' : 'function',
    \ 'm' : 'method',
    \ 'p' : 'property',
    \ }

let s:types.scope2kind = {
    \ 'class'    : 'c',
    \ 'function' : 'f',
    \ }

let g:vista#types#uctags#javascript# = s:types
