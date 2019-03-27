" Ant {{{1
let s:types = {}

let s:types.lang = 'ant'

let s:types.kinds = {
    \ 'p': {'long' : 'projects',   'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'antfiles',   'fold' : 0, 'stl' : 0},
    \ 'P': {'long' : 'properties', 'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'targets',    'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#ant# = s:types
