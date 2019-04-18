" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

if exists('b:current_syntax')
  finish
endif

let icons = join(values(g:vista#renderer#icons), '\|')
execute 'syntax match VistaIcon' '/'.icons.'/' 'contained'

syntax match VistaAccessPublic /^\s*+\</ contained
syntax match VistaAccessProtected /^\s*\~\</ contained
syntax match VistaAccessPrivate /^\s*-\</ contained

syntax match VistaArgs  /(.*)/
syntax match VistaColon /:/ contained
syntax match VistaLineNr /:\d*$/ contains=VistaColon
syntax match VistaScopeKind /: .*$/ contains=VistaArgs,VistaColon,VistaLineNr
syntax match VistaKind / \a*:\d*$/
syntax match VistaScope /^\S.*$/ contains=VistaAccessPrivate,VistaAccessProtected,VistaAccessPublic,VistaKind,VistaIcon
syntax region VistaTag start="^" end="$" contains=VistaLineNr,VistaScope,VistaAccessPrivate,VistaAccessProtected,VistaAccessPublic,VistaArgs,VistaScopeKind,VistaScoped

hi default link VistaScope       Function
hi default link VistaTag         Keyword
hi default link VistaKind        Type
hi default link VistaScopeKind   Define
hi default link VistaLineNr      LineNr
hi default link VistaColon       SpecialKey
hi default link VistaIcon        StorageClass
hi default link VistaArgs        Comment

hi default VistaAccessPublic     guifg=Green  ctermfg=Green cterm=bold gui=bold
hi default VistaAccessProtected  guifg=Yellow ctermfg=Yellow cterm=bold gui=bold
hi default VistaAccessPrivate    guifg=Red    ctermfg=Red cterm=bold gui=bold

let b:current_syntax = 'vista'
