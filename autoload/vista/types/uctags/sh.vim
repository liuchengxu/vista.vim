
" Shell script {{{1
let s:types = {}

let s:types.lang = 'sh'

let s:types.kinds = {
    \ 'f': {'long' : 'functions',    'fold' : 0, 'stl' : 1},
    \ 'a': {'long' : 'aliases',      'fold' : 0, 'stl' : 0},
    \ 's': {'long' : 'script files', 'fold' : 0, 'stl' : 0}
    \ }

" sh csh zsh
let g:vista#types#uctags#sh# = s:types
