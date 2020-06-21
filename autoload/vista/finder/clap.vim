" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! vista#finder#clap#Run(...) abort
  if !exists('g:loaded_clap')
    return vista#error#Need('https://github.com/liuchengxu/vim-clap')
  endif
  Clap tags
endfunction
