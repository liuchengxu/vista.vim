
" D {{{1
let s:types = {}

let s:types.lang = 'D'

let s:types.kinds = {
    \ 'M': {'long' : 'modules',              'fold' : 0, 'stl' : 1},
    \ 'V': {'long' : 'version statements',   'fold' : 1, 'stl' : 0},
    \ 'n': {'long' : 'namespaces',           'fold' : 0, 'stl' : 1},
    \ 'T': {'long' : 'templates',            'fold' : 0, 'stl' : 0},
    \ 'c': {'long' : 'classes',              'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'interfaces',           'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'structure names',      'fold' : 0, 'stl' : 1},
    \ 'g': {'long' : 'enumeration names',    'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'enumerators',          'fold' : 0, 'stl' : 0},
    \ 'u': {'long' : 'union names',          'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'function prototypes',  'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'function definitions', 'fold' : 0, 'stl' : 1},
    \ 'm': {'long' : 'members',              'fold' : 0, 'stl' : 1},
    \ 'a': {'long' : 'aliases',              'fold' : 1, 'stl' : 0},
    \ 'X': {'long' : 'mixins',               'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variable definitions', 'fold' : 0, 'stl' : 0},
    \ }

let s:types.sro = '.'

let s:types.kind2scope = {
    \ 'g' : 'enum',
    \ 'n' : 'namespace',
    \ 'i' : 'interface',
    \ 'c' : 'class',
    \ 's' : 'struct',
    \ 'u' : 'union'
    \ }

let s:types.scope2kind = {
    \ 'enum'      : 'g',
    \ 'namespace' : 'n',
    \ 'interface' : 'i',
    \ 'class'     : 'c',
    \ 'struct'    : 's',
    \ 'union'     : 'u'
    \ }

let g:vista#types#uctags#d# = s:types
