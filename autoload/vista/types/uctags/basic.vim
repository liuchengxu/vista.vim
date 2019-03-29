" Basic {{{1
let s:types = {}

let s:types.lang = 'basic'

let s:types.kinds = {
    \ 'c': {'long' : 'constants',    'fold' : 0, 'stl' : 1},
    \ 'g': {'long' : 'enumerations', 'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',    'fold' : 0, 'stl' : 1},
    \ 'l': {'long' : 'labels',       'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'types',        'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',    'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#basic# = s:types
