
" Pascal {{{1
let s:types = {}

let s:types.lang = 'pascal'

let s:types.kinds = {
    \ 'f': {'long' : 'functions',  'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'procedures', 'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#pascal# = s:types
