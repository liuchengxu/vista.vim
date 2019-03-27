" Clojure {{{1
let s:types = {}

let s:types.lang = 'clojure'

let s:types.kinds = {
    \ 'n': {'long': 'namespace', 'fold': 0, 'stl': 1},
    \ 'f': {'long': 'function',  'fold': 0, 'stl': 1},
    \ }

let s:types.sro = '.'

let s:types.kind2scope = {
    \ 'n' : 'namespace',
    \ }

let s:types.scope2kind = {
    \ 'namespace'  : 'n'
    \ }

let g:vista#types#uctags#clojure# = s:types
