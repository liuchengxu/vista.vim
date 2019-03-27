
" Verilog {{{1
let s:types = {}

let s:types.lang = 'verilog'

let s:types.kinds = {
    \ 'c': {'long' : 'constants',           'fold' : 0, 'stl' : 0},
    \ 'e': {'long' : 'events',              'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',           'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'modules',             'fold' : 0, 'stl' : 1},
    \ 'b': {'long' : 'blocks',              'fold' : 0, 'stl' : 1},
    \ 'n': {'long' : 'net data types',      'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'ports',               'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'register data types', 'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'tasks',               'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#verilog# = s:types
