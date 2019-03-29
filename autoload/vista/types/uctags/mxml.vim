
" Flex {{{1
" Vim doesn't support Flex out of the box, this is based on rough
" guesses and probably requires
" http://www.vim.org/scripts/script.php?script_id=2909
" Improvements welcome!
let s:types = {}

let s:types.lang = 'flex'

let s:types.kinds = {
    \ 'v': {'long' : 'global variables', 'fold' : 0, 'stl' : 0},
    \ 'c': {'long' : 'classes',          'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'methods',          'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'properties',       'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',        'fold' : 0, 'stl' : 1},
    \ 'x': {'long' : 'mxtags',           'fold' : 0, 'stl' : 0}
    \ }

let s:types.sro        = '.'

let s:types.kind2scope = {
    \ 'c' : 'class'
    \ }

let s:types.scope2kind = {
    \ 'class' : 'c'
    \ }

let g:vista#types#uctags#mxml# = s:types
