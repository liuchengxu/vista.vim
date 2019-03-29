
" VHDL {{{1
" The VHDL ctags parser unfortunately doesn't generate proper scopes
let s:types = {}

let s:types.lang = 'vhdl'

let s:types.kinds = {
    \ 'P': {'long' : 'packages',   'fold' : 1, 'stl' : 0},
    \ 'c': {'long' : 'constants',  'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'types',      'fold' : 0, 'stl' : 1},
    \ 'T': {'long' : 'subtypes',   'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'records',    'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'entities',   'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',  'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'procedures', 'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#vhdl# = s:types
