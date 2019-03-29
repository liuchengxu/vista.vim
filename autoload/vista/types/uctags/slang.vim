
" SLang {{{1
let s:types = {}

let s:types.lang = 'slang'

let s:types.kinds = {
    \ 'n': {'long' : 'namespaces', 'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',  'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#slang# = s:types
