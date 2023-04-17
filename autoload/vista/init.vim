" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! vista#init#Api() abort
  let g:vista = {}
  let g:vista.tmps = []

  " =========================================
  " Api for manipulating the vista buffer.
  " =========================================
  function! g:vista.winnr() abort
    return bufwinnr('__vista__')
  endfunction

  function! g:vista.winid() abort
    return bufwinid('__vista__')
  endfunction

  " Get original tagline given the lnum in vista sidebar
  "
  " Mind the offset
  function! g:vista.get_tagline_under_cursor() abort
    return get(g:vista.vlnum_cache, line('.') - g:vista#renderer#default#vlnum_offset, '')
  endfunction

  " =========================================
  " Api for manipulating the source buffer.
  " =========================================
  let source_handle = {}

  function! source_handle.get_winnr() abort
    return bufwinnr(self.bufnr)
  endfunction

  function! source_handle.get_winid() abort
    if has_key(self, 'winid')
      return self.winid
    else
      " A buffer can exist in two windows at the same time, this could be inaccurate.
      return bufwinid(self.bufnr)
    endif
  endfunction

  function! source_handle.filetype() abort
    return getbufvar(self.bufnr, '&filetype')
  endfunction

  function! source_handle.lines() abort
    return getbufline(self.bufnr, 1, '$')
  endfunction

  function! source_handle.line(lnum) abort
    let bufline = getbufline(self.bufnr, a:lnum)
    return empty(bufline) ? '' : bufline[0]
  endfunction

  function! source_handle.line_trimmed(lnum) abort
    let bufline = getbufline(self.bufnr, a:lnum)
    return empty(bufline) ? '' : vista#util#Trim(bufline[0])
  endfunction

  function! source_handle.extension() abort
    " Try the extension first, and then the filetype, for ctags relys on the extension name.
    let e = fnamemodify(self.fpath, ':e')
    return empty(e) ? getbufvar(self.bufnr, '&ft') : e
  endfunction

  function! source_handle.scope_seperator() abort
    let filetype = self.filetype()
    try
      let type = g:vista#types#uctags#{filetype}#
    catch /^Vim\%((\a\+)\)\=:E121/
      let type = {}
    endtry

    " FIXME use a default value maybe inappropriate.
    return get(type, 'sro', '.')
  endfunction

  let g:vista.source = source_handle

  " Skip an update once with this flag
  let g:vista.skip_once_flag = v:false

  hi default link VistaFloat Pmenu
endfunction
