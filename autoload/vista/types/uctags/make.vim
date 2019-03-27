
" Make {{{1
let s:types = {}

let s:types.lang = 'make'

let s:types.kinds = {
    \ 'I': {'long' : 'makefiles', 'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'macros',    'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'targets',   'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#make# = s:types
