" ASP {{{1
let s:types = {}

let s:types.lang = 'asp'

let s:types.kinds = {
    \ 'd': {'long' : 'constants',   'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'classes',     'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',   'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'subroutines', 'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',   'fold' : 0, 'stl' : 1}
    \ }

" aspperl aspvbs
let g:vista#types#uctags#aspvbs# = s:types
