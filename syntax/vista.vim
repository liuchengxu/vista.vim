" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

if exists('b:current_syntax')
  finish
endif

let icons = join(values(g:vista#renderer#icons), '\|')
execute 'syntax match VistaIcon' '/'.icons.'/' 'contained'

syntax match VistaPublic /^\s*+\</ contained
syntax match VistaProtected /^\s*\~\</ contained
syntax match VistaPrivate /^\s*-\</ contained

syntax match VistaParenthesis /(\|)/ contained
syntax match VistaArgs  /(.*)/ contains=VistaParenthesis
syntax match VistaColon /:\ze\d\+$/ contained
syntax match VistaLineNr /\d\+$/
syntax match VistaKind / \a*:\d*$/ contains=VistaColon,VistaLineNr
syntax match VistaScopeKind /: .*$/ contains=VistaArgs,VistaColon,VistaLineNr
syntax match VistaScope /^\S.*$/ contains=VistaPrivate,VistaProtected,VistaPublic,VistaKind,VistaIcon,VistaParenthesis
syntax region VistaTag start="^" end="$" contains=VistaPublic,VistaProtected,VistaPrivate,VistaArgs,VistaScope,VistaScopeKind

hi default link VistaParenthesis Operator
hi default link VistaScope       Function
hi default link VistaTag         Keyword
hi default link VistaKind        Type
hi default link VistaScopeKind   Define
hi default link VistaLineNr      LineNr
hi default link VistaColon       SpecialKey
hi default link VistaIcon        StorageClass
hi default link VistaArgs        Comment

hi default VistaPublic     guifg=Green  ctermfg=Green
hi default VistaProtected  guifg=Yellow ctermfg=Yellow
hi default VistaPrivate    guifg=Red    ctermfg=Red

let b:current_syntax = 'vista'
