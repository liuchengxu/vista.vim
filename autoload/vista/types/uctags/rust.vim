let s:types = {}

let s:types.lang = 'rust'

let s:types.kinds = {
    \ 'n': {'long' : 'module',          'fold' : 1, 'stl' : 0},
    \ 's': {'long' : 'struct',          'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'trait',           'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'implementation',  'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'function',        'fold' : 0, 'stl' : 1},
    \ 'g': {'long' : 'enum',            'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'type alias',      'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'global variable', 'fold' : 0, 'stl' : 1},
    \ 'M': {'long' : 'macro',           'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'struct field',    'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enum variant',    'fold' : 0, 'stl' : 1},
    \ 'P': {'long' : 'method',          'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '::'

let s:types.kind2scope = {
    \ 'n' : 'module',
    \ 's' : 'struct',
    \ 'i' : 'interface',
    \ 'c' : 'implementation',
    \ 'f' : 'function',
    \ 'g' : 'enum',
    \ 'P' : 'method',
    \ }

let s:types.scope2kind = {
    \ 'module'        : 'n',
    \ 'struct'        : 's',
    \ 'interface'     : 'i',
    \ 'implementation': 'c',
    \ 'function'      : 'f',
    \ 'enum'          : 'g',
    \ 'method'        : 'P',
    \ }

let g:vista#types#uctags#rust# = s:types
