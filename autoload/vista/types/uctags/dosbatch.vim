
" DOS Batch {{{1
let s:types = {}

let s:types.lang = 'dosbatch'

let s:types.kinds = {
    \ 'l': {'long' : 'labels',    'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables', 'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#dosbatch# = s:types
