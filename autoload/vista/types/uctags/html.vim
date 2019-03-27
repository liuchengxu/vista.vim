
" HTML {{{1
let type_html = {}

let type_html.lang = 'html'

let type_html.kinds = {
    \ 'a': {'long' : 'named anchors', 'fold' : 0, 'stl' : 1},
    \ 'h': {'long' : 'H1 headings',   'fold' : 0, 'stl' : 1},
    \ 'i': {'long' : 'H2 headings',   'fold' : 0, 'stl' : 1},
    \ 'j': {'long' : 'H3 headings',   'fold' : 0, 'stl' : 1},
    \ }

let g:vista#types#uctags#html# = s:types
