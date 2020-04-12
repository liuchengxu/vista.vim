" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Return the lines to preview and the target line number in the preview buffer.
function! vista#preview#GetLines(lnum) abort
  " Show 5 lines around the tag source line [lnum-5, lnum+5]
  let range = 5

  if a:lnum - range > 0
    let preview_lnum = range + 1
  else
    let preview_lnum = a:lnum
  endif

  let begin = max([a:lnum - range, 1])
  let end = begin + range * 2

  return [getbufline(g:vista.source.bufnr, begin, end), preview_lnum]
endfunction
