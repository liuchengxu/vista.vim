
" Ctags config {{{1
let s:types = {}

let s:types.lang = 'ctags'

let s:types.kinds = {
    \ 'l': {'long' : 'language definitions', 'fold' : 0, 'stl' : 1},
    \ 'k': {'long' : 'kind definitions',     'fold' : 0, 'stl' : 1},
    \ }

let s:types.sro = '.' " Not actually possible

let s:types.kind2scope = {
    \ 'l' : 'langdef',
    \ }

let s:types.scope2kind = {
    \ 'langdef' : 'l',
    \ }

let g:vista#types#uctags#ctags# = s:types
