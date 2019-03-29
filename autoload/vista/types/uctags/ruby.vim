
" Ruby {{{1
let s:types = {}

let s:types.lang = 'ruby'

let s:types.kinds = {
    \ 'm': {'long' : 'modules',           'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'classes',           'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'methods',           'fold' : 0, 'stl' : 1},
    \ 'S': {'long' : 'singleton methods', 'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '.'

let s:types.kind2scope = {
    \ 'c' : 'class',
    \ 'f' : 'method',
    \ 'm' : 'module'
    \ }

let s:types.scope2kind = {
    \ 'class'  : 'c',
    \ 'method' : 'f',
    \ 'module' : 'm'
    \ }

let g:vista#types#uctags#ruby# = s:types
