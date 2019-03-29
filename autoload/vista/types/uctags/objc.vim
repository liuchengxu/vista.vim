
" ObjectiveC {{{1
let s:types = {}

let s:types.lang = 'objectivec'

let s:types.kinds = {
    \ 'M': {'long' : 'preprocessor macros',   'fold' : 1, 'stl' : 0},
    \ 't': {'long' : 'type aliases',          'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'global variables',      'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'class interfaces',      'fold' : 0, 'stl' : 1},
    \ 'I': {'long' : 'class implementations', 'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'class methods',         'fold' : 0, 'stl' : 1},
    \ 'E': {'long' : 'object fields',         'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'object methods',        'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'type structures',       'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enumerations',          'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',             'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'properties',            'fold' : 0, 'stl' : 0},
    \ 'P': {'long' : 'protocols',             'fold' : 0, 'stl' : 0},
    \ }

let s:types.sro = ':'

let s:types.kind2scope = {
    \ 'i' : 'interface',
    \ 'I' : 'implementation',
    \ 's' : 'struct',
    \ 'p' : 'protocol',
    \ }

let s:types.scope2kind = {
    \ 'interface' : 'i',
    \ 'implementation' : 'I',
    \ 'struct' : 's',
    \ 'protocol' : 'p',
    \ }

let g:vista#types#uctags#objc# = s:types
