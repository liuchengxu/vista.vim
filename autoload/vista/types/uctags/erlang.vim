
" Erlang {{{1
let s:types = {}

let s:types.lang = 'erlang'

let s:types.kinds = {
    \ 'm': {'long' : 'modules',            'fold' : 0, 'stl' : 1},
    \ 'd': {'long' : 'macro definitions',  'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',          'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'record definitions', 'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'type definitions',   'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro        = '.' " Not sure, is nesting even possible?

let s:types.kind2scope = {
    \ 'm' : 'module'
    \ }

let s:types.scope2kind = {
    \ 'module' : 'm'
    \ }

let g:vista#types#uctags#erlang# = s:types
