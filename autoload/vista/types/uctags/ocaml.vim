
" Ocaml {{{1
let s:types = {}

let s:types.lang = 'ocaml'

let s:types.kinds = {
    \ 'M': {'long' : 'modules or functors', 'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'global variables',    'fold' : 0, 'stl' : 0},
    \ 'c': {'long' : 'classes',             'fold' : 0, 'stl' : 1},
    \ 'C': {'long' : 'constructors',        'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'methods',             'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'exceptions',          'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'type names',          'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',           'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'structure fields',    'fold' : 0, 'stl' : 0},
    \ 'p': {'long' : 'signature items',     'fold' : 0, 'stl' : 0}
    \ }

let s:types.sro = '.' " Not sure, is nesting even possible?

let s:types.kind2scope = {
    \ 'M' : 'Module',
    \ 'c' : 'class',
    \ 't' : 'type'
    \ }

let s:types.scope2kind = {
    \ 'Module' : 'M',
    \ 'class'  : 'c',
    \ 'type'   : 't'
    \ }

let g:vista#types#uctags#ocaml# = s:types
