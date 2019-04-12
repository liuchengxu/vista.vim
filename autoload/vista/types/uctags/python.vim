
" Python {{{1
let s:types = {}

let s:types.lang = 'python'

let s:types.kinds     = {
    \ 'i': {'long' : 'modules',   'fold' : 1, 'stl' : 0},
    \ 'c': {'long' : 'classes',   'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions', 'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'members',   'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables', 'fold' : 0, 'stl' : 0}
    \ }

let s:types.sro        = '.'
let s:types.kind2scope = {
    \ 'c' : 'class',
    \ 'f' : 'function',
    \ 'm' : 'member'
    \ }

let s:types.scope2kind = {
    \ 'class'    : 'c',
    \ 'function' : 'f',
    \ 'member'   : 'm'
    \ }

let g:vista#types#uctags#python# = s:types
