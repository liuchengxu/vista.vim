" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

if exists('b:current_syntax') && b:current_syntax ==# 'vista_markdown'
  finish
endif

syntax match VistaColon /:/ contained
syntax match VistaLineNr /\d\+$/

syntax match VistaHeadNr /H1\|H2\|H3\|H4\|H5\|H6:\d\+$/ contains=VistaLineNr contained

syntax match VistaH1 /.*H1/ contains=VistaColon,VistaLineNr,VistaHeadNr
syntax match VistaH2 /.*H2/ contains=VistaColon,VistaLineNr,VistaHeadNr
syntax match VistaH3 /.*H3/ contains=VistaColon,VistaLineNr,VistaHeadNr
syntax match VistaH4 /.*H4/ contains=VistaColon,VistaLineNr,VistaHeadNr
syntax match VistaH5 /.*H5/ contains=VistaColon,VistaLineNr,VistaHeadNr
syntax match VistaH6 /.*H6/ contains=VistaColon,VistaLineNr,VistaHeadNr

hi default link VistaColon       SpecialKey
hi default link VistaLineNr      LineNr
hi default link VistaHeadNr      Comment

highlight default link VistaH1 markdownH1
highlight default link VistaH2 markdownH2
highlight default link VistaH3 markdownH3
highlight default link VistaH4 markdownH4
highlight default link VistaH5 markdownH5
highlight default link VistaH6 markdownH6

let b:current_syntax = 'vista_markdown'
