
" C# {{{1
let s:types = {}

let s:types.lang = 'c#'

let s:types.kinds = {
    \ 'd': {'long' : 'macros',      'fold' : 1, 'stl' : 0},
    \ 'f': {'long' : 'fields',      'fold' : 0, 'stl' : 1},
    \ 'g': {'long' : 'enums',       'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enumerators', 'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'typedefs',    'fold' : 0, 'stl' : 1},
    \ 'n': {'long' : 'namespaces',  'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'interfaces',  'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'classes',     'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'structs',     'fold' : 0, 'stl' : 1},
    \ 'E': {'long' : 'events',      'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'methods',     'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'properties',  'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '.'

let s:types.kind2scope = {
    \ 'n' : 'namespace',
    \ 'i' : 'interface',
    \ 'c' : 'class',
    \ 's' : 'struct',
    \ 'g' : 'enum'
    \ }

let s:types.scope2kind = {
    \ 'namespace' : 'n',
    \ 'interface' : 'i',
    \ 'class'     : 'c',
    \ 'struct'    : 's',
    \ 'enum'      : 'g'
    \ }

let g:vista#types#uctags#cs# = s:types
