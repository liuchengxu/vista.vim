
" Lua {{{1
let s:types = {}

let s:types.lang = 'lua'

let s:types.kinds = {
    \ 'f': {'long' : 'functions', 'fold' : 0, 'stl' : 1}
    \ }

let g:vista#types#uctags# = s:types
