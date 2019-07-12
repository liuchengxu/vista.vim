" Autoconf {{{1
let s:types = {}

let s:types.lang = 'autoconf'

let s:types.kinds = {
    \ 'p': {'long': 'packages',            'fold': 0, 'stl': 1},
    \ 't': {'long': 'templates',           'fold': 0, 'stl': 1},
    \ 'm': {'long': 'autoconf macros',     'fold': 0, 'stl': 1},
    \ 'w': {'long': '"with" options',      'fold': 0, 'stl': 1},
    \ 'e': {'long': '"enable" options',    'fold': 0, 'stl': 1},
    \ 's': {'long': 'substitution keys',   'fold': 0, 'stl': 1},
    \ 'c': {'long': 'automake conditions', 'fold': 0, 'stl': 1},
    \ 'd': {'long': 'definitions',         'fold': 0, 'stl': 1}
    \ }

let g:vista#types#uctags#config# = s:types
