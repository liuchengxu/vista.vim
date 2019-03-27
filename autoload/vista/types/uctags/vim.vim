let s:types = {}

let s:types.lang = 'vim'

let s:types.kinds = {
    \ 'n': {'long' : 'vimball filenames',  'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',          'fold' : 1, 'stl' : 0},
    \ 'f': {'long' : 'functions',          'fold' : 0, 'stl' : 1},
    \ 'a': {'long' : 'autocommand groups', 'fold' : 1, 'stl' : 1},
    \ 'c': {'long' : 'commands',           'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'maps',               'fold' : 1, 'stl' : 0}
    \ }

let g:vista#types#uctags#vim# = s:types
