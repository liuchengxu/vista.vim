" BETA {{{1
let s:types = {}

let s:types.lang = 'beta'

let s:types.kinds = {
    \ 'f': {'long' : 'fragments', 'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'slots',     'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'patterns',  'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#beta# = s:types
