
" SQL {{{1
" The SQL ctags parser seems to be buggy for me, so this just uses the
" normal kinds even though scopes should be available. Improvements
" welcome!
let s:types = {}

let s:types.lang = 'sql'

let s:types.kinds = {
    \ 'P': {'long' : 'packages',               'fold' : 1, 'stl' : 1},
    \ 'd': {'long' : 'prototypes',             'fold' : 0, 'stl' : 1},
    \ 'c': {'long' : 'cursors',                'fold' : 0, 'stl' : 1},
    \ 'f': {'long' : 'functions',              'fold' : 0, 'stl' : 1},
    \ 'E': {'long' : 'record fields',          'fold' : 0, 'stl' : 1},
    \ 'L': {'long' : 'block label',            'fold' : 0, 'stl' : 1},
    \ 'p': {'long' : 'procedures',             'fold' : 0, 'stl' : 1},
    \ 's': {'long' : 'subtypes',               'fold' : 0, 'stl' : 1},
    \ 't': {'long' : 'tables',                 'fold' : 0, 'stl' : 1},
    \ 'T': {'long' : 'triggers',               'fold' : 0, 'stl' : 1},
    \ 'v': {'long' : 'variables',              'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'indexes',                'fold' : 0, 'stl' : 1},
    \ 'e': {'long' : 'events',                 'fold' : 0, 'stl' : 1},
    \ 'U': {'long' : 'publications',           'fold' : 0, 'stl' : 1},
    \ 'R': {'long' : 'services',               'fold' : 0, 'stl' : 1},
    \ 'D': {'long' : 'domains',                'fold' : 0, 'stl' : 1},
    \ 'V': {'long' : 'views',                  'fold' : 0, 'stl' : 1},
    \ 'n': {'long' : 'synonyms',               'fold' : 0, 'stl' : 1},
    \ 'x': {'long' : 'MobiLink Table Scripts', 'fold' : 0, 'stl' : 1},
    \ 'y': {'long' : 'MobiLink Conn Scripts',  'fold' : 0, 'stl' : 1},
    \ 'z': {'long' : 'MobiLink Properties',    'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags#sql# = s:types
