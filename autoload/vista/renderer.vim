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

let g:vista#renderer#icons = extend(s:icons, get(g:, 'vista_icons', {}))

function! vista#renderer#Decorate(kind) abort
  return get(g:vista#renderer#icons, a:kind, g:vista#renderer#icons.default).' '.a:kind
endfunction
