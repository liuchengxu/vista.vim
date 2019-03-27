
" R {{{1
let s:types = {}

let s:types.lang = 'R'

let s:types.kinds = {
    \ 'l': {'long' : 'libraries',          'fold' : 1, 'stl' : 0},
    \ 'f': {'long' : 'functions',          'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'sources',            'fold' : 0, 'stl' : 0},
    \ 'g': {'long' : 'global variables',   'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'function variables', 'fold' : 0, 'stl' : 0},
    \ }

let g:vista#types#uctags#r# = s:types
