" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:icons = {
\    'func': "\uf794",
\    'function': "\uf794",
\    'functions': "\uf794",
\    'var': "\uf71b",
\    'variable': "\uf71b",
\    'variables': "\uf71b",
\    'const': "\uf8ff",
\    'constant': "\uf8ff",
\    'method': "\uf6a6",
\    'package': "\ue612",
\    'packages': "\ue612",
\    'enum': "\uf702",
\    'enumerator': "\uf702",
\    'module': "\uf136",
\    'modules': "\uf136",
\    'type': "\uf7fd",
\    'typedef': "\uf7fd",
\    'types': "\uf7fd",
\    'field': "\uf30b",
\    'fields': "\uf30b",
\    'macro': "\uf8a3",
\    'macros': "\uf8a3",
\    'map': "\ufb44",
\    'class': "\uf0e8",
\    'augroup': "\ufb44",
\    'struct': "\uf318",
\    'union': "\ufacd",
\    'member': "\uf02b",
\    'target': "\uf893",
\    'property': "\ufab6",
\    'interface': "\uf7fe",
\    'namespace': "\uf475",
\    'subroutine': "\uf9af",
\    'implementation': "\uf776",
\    'typeParameter': "\uf278",
\    'default': "\uf29c"
\}

let g:vista#renderer#ctags = get(g:, 'vista#renderer#ctags', 'default')

let g:vista#renderer#icons = map(extend(s:icons, get(g:, 'vista#renderer#icons', {})), 'tolower(v:val)')

let g:vista#renderer#enable_icon = get(g:, 'vista#renderer#enable_icon',
      \ exists('g:vista#renderer#icons') || exists('g:airline_powerline_fonts'))

function! vista#renderer#IconFor(kind) abort
  if g:vista#renderer#enable_icon
    return get(g:vista#renderer#icons, tolower(a:kind), g:vista#renderer#icons.default)
  else
    return ''
  endif
endfunction

function! vista#renderer#Decorate(kind) abort
  if g:vista#renderer#enable_icon
    return vista#renderer#IconFor(a:kind).' '.a:kind
  else
    return a:kind
  endif
endfunction
