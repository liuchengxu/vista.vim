" Automake {{{1
let s:types = {}

let s:types.lang = 'automake'

let s:types.kinds = {
    \ 'I': {'long' : 'makefiles',   'fold' : 0, 'stl' : 1},
    \ 'd': {'long' : 'directories', 'fold' : 0, 'stl' : 1},
    \ 'P': {'long' : 'programs',    'fold' : 0, 'stl' : 1},
    \ 'M': {'long' : 'manuals',     'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'macros',      'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'targets',     'fold' : 0, 'stl' : 1},
    \ 'T': {'long' : 'ltlibraries', 'fold' : 0, 'stl' : 1},
    \ 'L': {'long' : 'libraries',   'fold' : 0, 'stl' : 1},
    \ 'S': {'long' : 'scripts',     'fold' : 0, 'stl' : 1},
    \ 'D': {'long' : 'datum',       'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'conditions',  'fold' : 0, 'stl' : 1},
    \ }

let g:vista#types#uctags#automake# = s:types
