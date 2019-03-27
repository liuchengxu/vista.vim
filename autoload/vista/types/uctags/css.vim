
" CSS {{{1
let s:types = {}

let s:types.lang = 'css'

let s:types.kinds = {
    \ 's': {'long' : 'selector',   'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'identities', 'fold' : 1, 'stl' : 0},
    \ 'c': {'long' : 'classes',    'fold' : 1, 'stl' : 0}
    \ }

let g:vista#types#uctags#css# = s:types
