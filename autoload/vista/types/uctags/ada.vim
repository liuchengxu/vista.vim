" Ada
let s:types = {}

let s:types.lang = 'ada'

let s:types.kinds = {
    \ 'P': {'long' : 'package specifications',        'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'packages',                      'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'types',                         'fold' : 0, 'stl' : 1},
    \ 'u': {'long' : 'subtypes',                      'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'record type components',        'fold' : 0, 'stl' : 1},
    \ 'l': {'long' : 'enum type literals',            'fold' : 0, 'stl' : 0},
    \ 'v': {'long' : 'variables',                     'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'generic formal parameters',     'fold' : 0, 'stl' : 0},
    \ 'n': {'long' : 'constants',                     'fold' : 0, 'stl' : 0},
    \ 'x': {'long' : 'user defined exceptions',       'fold' : 0, 'stl' : 1},
    \ 'R': {'long' : 'subprogram specifications',     'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'subprograms',                   'fold' : 0, 'stl' : 1},
    \ 'K': {'long' : 'task specifications',           'fold' : 0, 'stl' : 1},
    \ 'k': {'long' : 'tasks',                         'fold' : 0, 'stl' : 1},
    \ 'O': {'long' : 'protected data specifications', 'fold' : 0, 'stl' : 1},
    \ 'o': {'long' : 'protected data',                'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'task/protected data entries',   'fold' : 0, 'stl' : 1},
    \ 'b': {'long' : 'labels',                        'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'loop/declare identifiers',      'fold' : 0, 'stl' : 1},
    \ }

let s:types.sro = '.' " Not sure if possible

let s:types.kind2scope = {
    \ 'P' : 'packspec',
    \ 't' : 'type',
    \ }

let s:types.scope2kind = {
    \ 'packspec' : 'P',
    \ 'type'     : 't',
    \ }

let g:vista#types#uctags#ada# = s:types
