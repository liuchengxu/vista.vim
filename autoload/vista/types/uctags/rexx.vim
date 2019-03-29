
" REXX {{{1
let s:types = {}

let s:types.lang = 'rexx'

let s:types.kinds     = {
    \ 's': {'long' : 'subroutines', 'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#rexx# = s:types
