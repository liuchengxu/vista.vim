" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Which filetype the current sidebar should be.
function! vista#sidebar#WhichFileType() abort
  if t:vista.provider ==# 'coc'
        \ || (t:vista.provider ==# 'ctags' && g:vista#renderer#ctags ==# 'default')
    return 'vista'
  elseif t:vista.provider ==# 'markdown'
    return 'vista_markdown'
  else
    return 'vista_kind'
  endif
endfunction

function! s:NewWindow() abort
  let position = get(g:, 'vista_sidebar_position', 'vertical botright')
  let width = get(g:, 'vista_sidebar_width', 30)
  let open = position.' '.width.'new'
  silent execute open '__vista__'

  execute 'setlocal filetype='.vista#sidebar#WhichFileType()

  " FIXME when to delete?
  if has_key(t:vista.source, 'fpath')
    let w:vista_first_line_hi_id = matchaddpos('MoreMsg', [1])
  endif
endfunction

" Reload vista buffer given the unrendered data
function! vista#sidebar#Reload(data) abort
  " empty(a:data):
  "   May be triggered by autocmd event sometimes
  "   e.g., unsupported filetypes for ctags or no related language servers.
  "
  " !has_key(t:vista, 'bufnr'):
  "   May opening a new tab if bufnr does not exist in t:vista.
  "
  " t:vista.winnr() == -1:
  "   vista window is not visible.
  if empty(a:data)
        \ || !has_key(t:vista, 'bufnr')
        \ || t:vista.winnr() == -1
    return
  endif

  let rendered = vista#renderer#Render(a:data)
  call vista#util#SetBufline(t:vista.bufnr, rendered)
endfunction

" Open or update vista buffer given the rendered rows.
function! vista#sidebar#OpenOrUpdate(rows) abort
  " (Re)open a window and move to it
  if !exists('t:vista.bufnr')
    call s:NewWindow()
    let t:vista = get(t:, 'vista', {})
    let t:vista.bufnr = bufnr('%')
    let t:vista.winid = win_getid()
    let t:vista.pos = [winsaveview(), winnr(), winrestcmd()]
  else
    let winnr = t:vista.winnr()
    if winnr == -1
      call s:NewWindow()
    elseif winnr() != winnr
      noautocmd execute winnr.'wincmd w'
    endif
  endif

  if exists('#User#VistaWinOpen')
    doautocmd User VistaWinOpen
  endif

  call vista#util#SetBufline(t:vista.bufnr, a:rows)

  if has_key(t:vista, 'lnum')
    call vista#cursor#ShowTagFor(t:vista.lnum)
    unlet t:vista.lnum
  endif

  if !get(g:, 'vista_stay_on_open', 1)
    wincmd p
  endif
endfunction

function! vista#sidebar#Close() abort
  if exists('t:vista.bufnr')
    let winnr = t:vista.winnr()
    if winnr != -1
      noautocmd execute winnr.'wincmd c'
    endif

    " Jump back to the previous window if we are in the vista sidebar atm.
    if winnr == winnr()
      wincmd p
    endif

    silent execute  t:vista.bufnr.'bwipe!'
    unlet t:vista.bufnr
  endif

  call s:ClearAugroups('VistaCoc', 'VistaCtags')

  call vista#win#CloseFloating()
endfunction

function! s:ClearAugroups(...) abort
  for aug in a:000
    if exists('#'.aug)
      execute 'autocmd!' aug
    endif
  endfor
endfunction

function! vista#sidebar#Open() abort
  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]
  call vista#source#Update(bufnr, winnr, fname, fpath)

  " Support the builtin markdown toc extension as an executive
  if vista#HasTOCSupport()
    call vista#TryRunTOC()
  else
    let executive = vista#GetExplicitExecutiveOrDefault()
    call vista#executive#{executive}#Execute(v:false, v:true, v:false)
  endif
endfunction

function! vista#sidebar#IsOpen() abort
  return bufwinnr('__vista__') != -1
endfunction

function! vista#sidebar#ToggleFocus() abort
  if !exists('t:vista') || t:vista.winnr() == -1
    call vista#sidebar#Open()
    return
  endif
  let winnr = t:vista.winnr()
  if winnr != winnr()
    execute winnr.'wincmd w'
  else
    execute t:vista.source.winnr().'wincmd w'
  endif
endfunction

function! vista#sidebar#Toggle() abort
  if vista#sidebar#IsOpen()
    call vista#sidebar#Close()
  else
    call vista#sidebar#Open()
  endif
endfunction
