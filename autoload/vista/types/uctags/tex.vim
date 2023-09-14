
" LaTeX {{{1
let s:types = {}

let s:types.lang = 'tex'

let s:types.kinds = {
    \ 'p': {'long' : 'parts',          'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'chapters',       'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'sections',       'fold' : 0, 'stl' : 1},
    \ 'u': {'long' : 'subsections',    'fold' : 0, 'stl' : 1},
    \ 'b': {'long' : 'subsubsections', 'fold' : 0, 'stl' : 1},
    \ 'P': {'long' : 'paragraphs',     'fold' : 0, 'stl' : 0},
    \ 'G': {'long' : 'subparagraphs',  'fold' : 0, 'stl' : 0},
    \ 'l': {'long' : 'labels',         'fold' : 0, 'stl' : 0},
    \ 'i': {'long' : 'includes',       'fold' : 1, 'stl' : 0},
    \ 'B': {'long' : 'bibliography',       'fold' : 0, 'stl' : 0},
    \ 'C': {'long' : 'command',       'fold' : 0, 'stl' : 0},
    \ 'o': {'long' : 'mathoperator',       'fold' : 0, 'stl' : 0},
    \ 'e': {'long' : 'environment',       'fold' : 0, 'stl' : 0},
    \ 't': {'long' : 'theorem',       'fold' : 0, 'stl' : 0},
    \ 'N': {'long' : 'counter',       'fold' : 0, 'stl' : 0},
    \ }

let s:types.sro = '""'

let s:types.kind2scope = {
    \ 'p' : 'part',
    \ 'c' : 'chapter',
    \ 's' : 'section',
    \ 'u' : 'subsection',
    \ 'b' : 'subsubsection',
    \ }

let s:types.scope2kind = {
    \ 'part'          : 'p',
    \ 'chapter'       : 'c',
    \ 'section'       : 's',
    \ 'subsection'    : 'u',
    \ 'subsubsection' : 'b',
    \ }

let s:types.sort = 0

let g:vista#types#uctags#tex# = s:types
