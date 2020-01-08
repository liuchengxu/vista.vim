" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

if exists('b:current_syntax') && b:current_syntax ==# 'vista_lsp'
  finish
endif

let icons = join(values(g:vista#renderer#icons), '\|')
execute 'syntax match VistaIcon' '/'.icons.'/' 'contained'

syntax match VistaColon /:\ze\d\+$/ contained
syntax match VistaLineNr /\d\+$/
syntax match VistaKind /\S\+\zs \a*:\d*$/ contains=VistaColon,VistaLineNr
syntax region VistaTag start="^" end="$" contains=VistaKind,VistaColon,VistaLineNr

hi default link VistaParenthesis Operator
hi default link VistaScope       Function
hi default link VistaTag         Keyword
hi default link VistaKind        Comment
hi default link VistaScopeKind   Define
hi default link VistaLineNr      LineNr
hi default link VistaColon       SpecialKey
hi default link VistaIcon        StorageClass

" Do not touch the global highlight group.
" hi! link Folded Function

if has('nvim')
  call setwinvar(winnr(), '&winhl', 'Folded:Function')
endif

let b:current_syntax = 'vista_lsp'
