" COBOL {{{1
let s:types = {}

let s:types.lang = 'cobol'

let s:types.kinds = {
    \ 'd': {'long' : 'data items',        'fold' : 0, 'stl' : 1},
    \ 'D': {'long' : 'divisions',         'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'file descriptions', 'fold' : 0, 'stl' : 1},
    \ 'g': {'long' : 'group items',       'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'paragraphs',        'fold' : 0, 'stl' : 1},
    \ 'P': {'long' : 'program ids',       'fold' : 0, 'stl' : 1},
    \ 'S': {'long' : 'source code file',  'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'sections',          'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#cobol# = s:types
