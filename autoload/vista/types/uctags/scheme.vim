
" scheme {{{1
let s:types = {}

let s:types.lang = 'scheme'

let s:types.kinds = {
  \ 'f': {'long' : 'functions', 'fold' : 0, 'stl' : 1},
  \ 's': {'long' : 'sets',      'fold' : 0, 'stl' : 1}
  \ }

" scheme racket
let g:vista#types#uctags#scheme# = s:types
