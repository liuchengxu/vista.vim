
" Fortran {{{1
let s:types = {}

let s:types.lang = 'fortran'

let s:types.kinds = {
    \ 'm': {'long' : 'modules',    'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'programs',   'fold' : 0, 'stl' : 1},
    \ 'k': {'long' : 'components', 'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'derived types and structures', 'fold' : 0,'stl' : 1},
    \ 'c': {'long' : 'common blocks', 'fold' : 0, 'stl' : 1},
    \ 'b': {'long' : 'block data',    'fold' : 0, 'stl' : 0},
    \ 'E': {'long' : 'enumerations',  'fold' : 0, 'stl' : 1},
    \ 'N': {'long' : 'enumeration values', 'fold' : 0, 'stl' : 0},
    \ 'e': {'long' : 'entry points',  'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',     'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'subroutines',   'fold' : 0, 'stl' : 1},
    \ 'M': {'long' : 'type bound procedures',   'fold' : 0,'stl' : 1},
    \ 'l': {'long' : 'labels',        'fold' : 0, 'stl' : 1},
    \ 'n': {'long' : 'namelists',     'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',     'fold' : 0, 'stl' : 0}
    \ }

let s:types.sro = '.' " Not sure, is nesting even possible?

let s:types.kind2scope = {
    \ 'm' : 'module',
    \ 'p' : 'program',
    \ 'f' : 'function',
    \ 's' : 'subroutine'
    \ }

let s:types.scope2kind = {
    \ 'module'     : 'm',
    \ 'program'    : 'p',
    \ 'function'   : 'f',
    \ 'subroutine' : 's'
    \ }

let g:vista#types#uctags#fortran# = s:types
