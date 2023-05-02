" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

let s:icons = {
\    'func': "\Uf0295",
\    'function': "\Uf0295",
\    'functions': "\Uf0295",
\    'var': "\uea88",
\    'variable': "\uea88",
\    'variables': "\uea88",
\    'const': "\ueb5d",
\    'constant': "\ueb5d",
\    'constructor': "\uf976",
\    'method': "\uea8c",
\    'package': "\ueb29",
\    'packages': "\ueb29",
\    'enum': "\uea95",
\    'enummember': "\ueb5e",
\    'enumerator': "\uea95",
\    'module': "\ueaec",
\    'modules': "\ueaec",
\    'type': "\uebb9",
\    'typedef': "\uebb9",
\    'types': "\uebb9",
\    'field': "\ueb5f",
\    'fields': "\ueb5f",
\    'macro': "\Uf03a4",
\    'macros': "\Uf03a4",
\    'map': "\Uf0645",
\    'class': "\ueb5b",
\    'augroup': "\Uf0645",
\    'struct': "\uea91",
\    'union': "\Uf0564",
\    'member': "\uf02b",
\    'target': "\Uf0394",
\    'property': "\ueb65",
\    'interface': "\ueb61",
\    'namespace': "\uea8b",
\    'subroutine': "\Uf04b0",
\    'implementation': "\uebba",
\    'typeParameter': "\uea92",
\    'default': "\uf29c"
\}

let g:vista#renderer#ctags = get(g:, 'vista#renderer#ctags', 'default')
let g:vista#renderer#icons = map(extend(s:icons, get(g:, 'vista#renderer#icons', {})), 'tolower(v:val)')
let g:vista#renderer#enable_icon = get(g:, 'vista#renderer#enable_icon',
      \ exists('g:vista#renderer#icons') || exists('g:airline_powerline_fonts'))
let g:vista#renderer#enable_kind = get(g:, 'vista#renderer#enable_kind', !g:vista#renderer#enable_icon)

function! vista#renderer#IconFor(kind) abort
  if g:vista#renderer#enable_icon
    let key = tolower(a:kind)
    if has_key(g:vista#renderer#icons, key)
      return g:vista#renderer#icons[key]
    else
      return get(g:vista#renderer#icons, 'default', '?')
    endif
  else
    return ''
  endif
endfunction

function! vista#renderer#KindFor(kind) abort
  if g:vista#renderer#enable_kind
    return a:kind
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

function! s:Render(data) abort
  if g:vista.provider ==# 'coc' && type(a:data) == v:t_list
    return vista#renderer#hir#lsp#Coc(a:data)
  elseif g:vista.provider ==# 'ctags' && g:vista#renderer#ctags ==# 'default'
    return vista#renderer#hir#ctags#Render()
  else
    " The kind renderer applys to the LSP provider.
    return vista#renderer#kind#Render(a:data)
  endif
endfunction

" Render the extracted data to rows
function! vista#renderer#Render(data) abort
  return s:Render(a:data)
endfunction

function! vista#renderer#RenderAndDisplay(data) abort
  call vista#sidebar#OpenOrUpdate(s:Render(a:data))
endfunction

" Convert the number kind to the text kind, and then
" extract the neccessary info from the raw LSP response.
function! vista#renderer#LSPPreprocess(lsp_result) abort
  let lines = []
  call map(a:lsp_result, 'vista#parser#lsp#KindToSymbol(v:val, lines)')

  let processed_data = {}
  let g:vista.functions = []
  call map(lines, 'vista#parser#lsp#ExtractSymbol(v:val, processed_data)')

  return processed_data
endfunction

" React on the preprocessed LSP data
function! vista#renderer#LSPProcess(processed_data, reload_only, should_display) abort
  " Always reload the data, display the processed data on demand.
  if a:should_display
    call vista#Debug('[LSPProcess]should_display, processed_data:'.string(a:processed_data))
    call vista#renderer#RenderAndDisplay(a:processed_data)
    return [a:reload_only, v:false]
  else
    call vista#Debug('[LSPProcess]reload_only, processed_data:'.string(a:processed_data))
    call vista#sidebar#Reload(a:processed_data)
    return [v:true, a:should_display]
  endif
endfunction
