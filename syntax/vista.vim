" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

if exists('b:current_syntax')
  finish
endif

let icons = join(values(g:vista#renderer#icons), '\|')
execute 'syntax match VistaIcon' '/'.icons.'/' 'contained'

syntax match VistaAccessPublic /+\</ contained
syntax match VistaAccessProtected /#\</ contained
syntax match VistaAccessPrivate /-\</ contained

syntax match VistaColon /:/ contained
syntax match VistaLineNr /:\d*$/ contains=VistaColon
syntax match VistaKind / \a*:\d*$/ contains=VistaLineNr
syntax match VistaScope /^\S.*$/ contains=VistaAccessPrivate,VistaAccessProtected,VistaAccessPublic,VistaKind,VistaIcon
syntax region VistaTag start="^" end="$" contains=VistaLineNr,VistaScope,VistaAccessPrivate,VistaAccessProtected,VistaAccessPublic

hi default link VistaScope       Function
hi default link VistaTag         Keyword
hi default link VistaKind        Type
hi default link VistaLineNr      LineNr
hi default link VistaColon       SpecialKey
hi default link VistaIcon        StorageClass

hi default VistaAccessPublic     guifg=Green  ctermfg=Green
hi default VistaAccessProtected  guifg=Yellow ctermfg=Yellow
hi default VistaAccessPrivate    guifg=Red    ctermfg=Red

let b:current_syntax = 'vista'
