
" Vala {{{1
" Vala is supported by the ctags fork provided by Anjuta, so only add the
" type if the fork is used to prevent error messages otherwise
let s:types = {}

let s:types.lang = 'vala'

let s:types.kinds = {
    \ 'e': {'long' : 'Enumerations',       'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'Enumeration values', 'fold' : 0, 'stl' : 0},
    \ 's': {'long' : 'Structures',         'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'Interfaces',         'fold' : 0, 'stl' : 1},
    \ 'd': {'long' : 'Delegates',          'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'Classes',            'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'Properties',         'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'Fields',             'fold' : 0, 'stl' : 0},
    \ 'm': {'long' : 'Methods',            'fold' : 0, 'stl' : 1},
    \ 'E': {'long' : 'Error domains',      'fold' : 0, 'stl' : 1},
    \ 'r': {'long' : 'Error codes',        'fold' : 0, 'stl' : 1},
    \ 'S': {'long' : 'Signals',            'fold' : 0, 'stl' : 1}
    \ }

let s:types.sro = '.'

" 'enum' doesn't seem to be used as a scope, but it can't hurt to have
" it here
let s:types.kind2scope = {
    \ 's' : 'struct',
    \ 'i' : 'interface',
    \ 'c' : 'class',
    \ 'e' : 'enum'
    \ }

let s:types.scope2kind = {
    \ 'struct'    : 's',
    \ 'interface' : 'i',
    \ 'class'     : 'c',
    \ 'enum'      : 'e'
    \ }

let g:vista#types#uctags#vala# = s:types

if executable('anjuta-tags')
  let g:vista#types#uctags#vala#.ctagsbin = 'anjuta-tags'
endif
