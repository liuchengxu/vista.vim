
" Matlab {{{1
let s:types = {}

let s:types.lang = 'matlab'

let s:types.kinds = {
    \ 'f': {'long' : 'functions', 'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables', 'fold' : 0, 'stl' : 0}
    \ }

let g:vista#types#uctags#matlab# = s:types
