
" LaTeX {{{1
let s:types = {}

let s:types.lang = 'tex'

let s:types.kinds = {
    \ 'i': {'long' : 'includes',       'fold' : 1, 'stl' : 0},
    \ 'p': {'long' : 'parts',          'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'chapters',       'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'sections',       'fold' : 0, 'stl' : 1},
    \ 'u': {'long' : 'subsections',    'fold' : 0, 'stl' : 1},
    \ 'b': {'long' : 'subsubsections', 'fold' : 0, 'stl' : 1},
    \ 'P': {'long' : 'paragraphs',     'fold' : 0, 'stl' : 0},
    \ 'G': {'long' : 'subparagraphs',  'fold' : 0, 'stl' : 0},
    \ 'l': {'long' : 'labels',         'fold' : 0, 'stl' : 0},
    \ 'f': {'long' : 'frame',          'fold' : 0, 'stl' : 0},
    \ 'g': {'long' : 'subframe',       'fold' : 0, 'stl' : 0}
    \ }

let s:types.sro = '""'

let s:types.kind2scope = {
    \ 'p' : 'part',
    \ 'c' : 'chapter',
    \ 's' : 'section',
    \ 'u' : 'subsection',
    \ 'b' : 'subsubsection',
    \ 'f' : 'frame',
    \ 'g' : 'subframe'
    \ }

let s:types.scope2kind = {
    \ 'part'          : 'p',
    \ 'chapter'       : 'c',
    \ 'section'       : 's',
    \ 'subsection'    : 'u',
    \ 'subsubsection' : 'b',
    \ 'frame'         : 'f',
    \ 'subframe'      : 'g'
    \ }

let s:types.sort = 0

let g:vista#types#uctags#tex# = s:types
