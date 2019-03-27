
" SML {{{1
let s:types = {}

let s:types.lang = 'sml'

let s:types.kinds = {
    \ 'e': {'long' : 'exception declarations', 'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'function definitions',   'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'functor definitions',    'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'signature declarations', 'fold' : 0, 'stl' : 0},
    \ 'r': {'long' : 'structure declarations', 'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'type definitions',       'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'value bindings',         'fold' : 0, 'stl' : 0}
    \ }

let g:vista#types#uctags#sml# = s:types
