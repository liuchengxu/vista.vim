
" Python {{{1
let s:types = {}

let s:types.lang = 'python'

let s:types.kinds     = {
    \ {'short' : 'i', 'long' : 'modules',   'fold' : 1, 'stl' : 0},
    \ {'short' : 'c', 'long' : 'classes',   'fold' : 0, 'stl' : 1},
    \ {'short' : 'f', 'long' : 'functions', 'fold' : 0, 'stl' : 1},
    \ {'short' : 'm', 'long' : 'members',   'fold' : 0, 'stl' : 1},
    \ {'short' : 'v', 'long' : 'variables', 'fold' : 0, 'stl' : 0}
    \ }

let s:types.sro        = '.'
let s:types.kind2scope = {
    \ 'c' : 'class',
    \ 'f' : 'function',
    \ 'm' : 'function'
    \ }

let s:types.scope2kind = {
    \ 'class'    : 'c',
    \ 'function' : 'f'
    \ }

let s:types.kind2scope.m = 'member'
let s:types.scope2kind.member = 'm'

let g:vista#types#uctags#python# = s:types
