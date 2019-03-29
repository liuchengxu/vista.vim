" Asm {{{1
let s:types = {}

let s:types.lang = 'asm'

let s:types.kinds = {
    \ 'm': {'long' : 'macros',    'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'types',     'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'sections',  'fold' : 0, 'stl' : 1},
    \ 'd': {'long' : 'defines',   'fold' : 0, 'stl' : 1},
    \ 'l': {'long' : 'labels',    'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#asm# = s:types
