
" Vera {{{1
" Why are variables 'virtual'?
let s:types = {}

let s:types.lang = 'vera'

let s:types.kinds = {
    \ 'h': {'long' : 'header files', 'fold' : 1, 'stl' : 0},
    \ 'd': {'long' : 'macros',      'fold' : 1, 'stl' : 0},
    \ 'g': {'long' : 'enums',       'fold' : 0, 'stl' : 1},
    \ 'T': {'long' : 'typedefs',    'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'interfaces',  'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'classes',     'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enumerators', 'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'members',     'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',   'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'signals',     'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'tasks',       'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',   'fold' : 0, 'stl' : 0},
    \ 'p': {'long' : 'programs',    'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro        = '.' " Nesting doesn't seem to be possible

let s:types.kind2scope = {
    \ 'g' : 'enum',
    \ 'c' : 'class',
    \ 'v' : 'virtual'
    \ }

let s:types.scope2kind = {
    \ 'enum'      : 'g',
    \ 'class'     : 'c',
    \ 'virtual'   : 'v'
    \ }

let g:vista#types#uctags#vera# = s:types
