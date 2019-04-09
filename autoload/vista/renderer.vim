" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:icons = {
\    "function": "\uf794",
\    "method": "\uf6a6",
\    "variable": "\uf71b",
\    "constant": "\uf8ff",
\    "struct": "\ufb44",
\    "class": "\uf0e8",
\    "interface": "\ufa52",
\    "text": "\ue612",
\    "enum": "\uf435",
\    "enumMember": "\uf02b",
\    "module": "\uf668",
\    "color": "\ue22b",
\    "property": "\ufab6",
\    "field": "\uf93d",
\    "unit": "\uf475",
\    "file": "\uf471",
\    "value": "\uf8a3",
\    "event": "\ufacd",
\    "keyword": "\uf893",
\    "operator": "\uf915",
\    "reference": "\uf87a",
\    "typeParameter": "\uf278",
\    "default": "\uf29c"
\}

let g:vista#renderer#icons = map(extend(s:icons, get(g:, 'vista#renderer#icons', {})), 'tolower(v:val)')

let g:vista#renderer#enable_icon = get(g:, 'vista#renderer#enable_icon',
      \ exists('g:vista#renderer#icons') || exists('g:airline_powerline_fonts'))

function! vista#renderer#Decorate(kind) abort
  if g:vista#renderer#enable_icon
    return get(g:vista#renderer#icons, tolower(a:kind), g:vista#renderer#icons.default).' '.a:kind
  else
    return a:kind
  endif
endfunction
