" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:icons = {
\    'func': "\uf794",
\    'function': "\uf794",
\    'var': "\uf71b",
\    'variable': "\uf71b",
\    'const': "\uf8ff",
\    'constant': "\uf8ff",
\    'method': "\uf6a6",
\    'package': "\ue612",
\    'packages': "\ue612",
\    'enum': "\uf435",
\    'enumerator': "\uf435",
\    'module': "\uf668",
\    'modules': "\uf668",
\    'type': "\ue22b",
\    'typedef': "\ue22b",
\    'types': "\ue22b",
\    'field': "\uf93d",
\    'fields': "\uf93d",
\    'macro': "\uf8a3",
\    'macros': "\uf8a3",
\    'map': "\ufb44",
\    'class': "\uf0e8",
\    'augroup': "\ufb44",
\    'struct': "\ufb44",
\    'union': "\ufacd",
\    'member': "\uf02b",
\    'target': "\uf893",
\    'property': "\ufab6",
\    'interface': "\ufa52",
\    'namespace': "\uf475",
\    'subroutine': "\uf915",
\    'implementation': "\uf87a",
\    'typeParameter': "\uf278",
\    'default': "\uf29c"
\}

let g:vista#renderer#icons = map(extend(s:icons, get(g:, 'vista#renderer#icons', {})), 'tolower(v:val)')

let g:vista#renderer#enable_icon = get(g:, 'vista#renderer#enable_icon',
      \ exists('g:vista#renderer#icons') || exists('g:airline_powerline_fonts'))

function! vista#renderer#Decorate(kind) abort
  if g:vista#renderer#enable_icon
    return get(g:vista#renderer#icons, tolower(a:kind), g:vista#renderer#icons.default).'  '.a:kind
  else
    return a:kind
  endif
endfunction
