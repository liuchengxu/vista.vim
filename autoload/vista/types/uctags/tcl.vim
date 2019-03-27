
" Tcl {{{1
let s:types = {}

let s:types.lang = 'tcl'

let s:types.kinds = {
    \ 'n': {'long' : 'namespaces', 'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'procedures', 'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#tcl# = s:types
