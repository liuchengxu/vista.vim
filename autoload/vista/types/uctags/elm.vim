
" Elm {{{1
" based on https://github.com/bitterjug/vim-tagbar-ctags-elm/blob/master/ftplugin/elm/tagbar-elm.vim
let s:types = {}

let s:types.lang = 'elm'

let s:types.kinds = {
    \ 'm': {'long' : 'modules',           'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'imports',           'fold' : 1, 'stl' : 0},
    \ 't': {'long' : 'types',             'fold' : 1, 'stl' : 0},
    \ 'a': {'long' : 'type aliases',      'fold' : 0, 'stl' : 0},
    \ 'c': {'long' : 'type constructors', 'fold' : 0, 'stl' : 0},
    \ 'p': {'long' : 'ports',             'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'functions',         'fold' : 1, 'stl' : 0},
    \ }

let s:types.sro = ':'

let s:types.kind2scope = {
    \ 'f' : 'function',
    \ 'm' : 'module',
    \ 't' : 'type'
    \ }

let s:types.scope2kind = {
    \ 'function' : 'f',
    \ 'module'   : 'm',
    \ 'type'     : 't'
    \ }

let g:vista#types#uctags#elm# = s:types
