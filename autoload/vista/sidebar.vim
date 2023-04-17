" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Which filetype the current sidebar should be.
function! vista#sidebar#WhichFileType() abort
  if g:vista.provider ==# 'coc'
        \ || (g:vista.provider ==# 'ctags' && g:vista#renderer#ctags ==# 'default')
    return 'vista'
  elseif g:vista.provider ==# 'markdown'
    return 'vista_markdown'
  else
    return 'vista_kind'
  endif
endfunction

function! s:NewWindow() abort
  if exists('g:vista_sidebar_open_cmd')
    let open = g:vista_sidebar_open_cmd
  else
    let open = g:vista_sidebar_position.' '.g:vista_sidebar_width.'new'
  endif

  if get(g:, 'vista_sidebar_keepalt', 0)
    silent execute 'keepalt '.open '__vista__'
  else
    silent execute open '__vista__'
  endif

  execute 'setlocal filetype='.vista#sidebar#WhichFileType()

  " FIXME when to delete?
  if has_key(g:vista.source, 'fpath')
    let w:vista_first_line_hi_id = matchaddpos('MoreMsg', [1])
  endif
endfunction

" Reload vista buffer given the unrendered data
function! vista#sidebar#Reload(data) abort
  " empty(a:data):
  "   May be triggered by autocmd event sometimes
  "   e.g., unsupported filetypes for ctags or no related language servers.
  "
  " !has_key(g:vista, 'bufnr'):
  "   May opening a new tab if bufnr does not exist in g:vista.
  "
  " g:vista.winnr() == -1:
  "   vista window is not visible.
  if empty(a:data)
        \ || !has_key(g:vista, 'bufnr')
        \ || g:vista.winnr() == -1
    return
  endif

  let rendered = vista#renderer#Render(a:data)
  call vista#util#SetBufline(g:vista.bufnr, rendered)
endfunction

" Open or update vista buffer given the rendered rows.
function! vista#sidebar#OpenOrUpdate(rows) abort
  " (Re)open a window and move to it
  if !exists('g:vista.bufnr')
    call s:NewWindow()
    let g:vista = get(g:, 'vista', {})
    let g:vista.bufnr = bufnr('%')
    let g:vista.winid = win_getid()
    let g:vista.pos = [winsaveview(), winnr(), winrestcmd()]
  else
    let winnr = g:vista.winnr()
    if winnr == -1
      call s:NewWindow()
    elseif winnr() != winnr
      noautocmd execute winnr.'wincmd w'
    endif
  endif

  call vista#util#SetBufline(g:vista.bufnr, a:rows)

  if has_key(g:vista, 'lnum')
    call vista#cursor#ShowTagFor(g:vista.lnum)
    unlet g:vista.lnum
  endif

  if !g:vista_stay_on_open
    wincmd p
  endif
endfunction

function! vista#sidebar#Close() abort
  if exists('g:vista.bufnr')
    let winnr = g:vista.winnr()

    " Jump back to the previous window if we are in the vista sidebar atm.
    if winnr == winnr()
      wincmd p
    endif

    if winnr != -1
      noautocmd execute winnr.'wincmd c'
    endif

    silent execute  g:vista.bufnr.'bwipe!'
    unlet g:vista.bufnr
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
  if vista#toc#IsSupported(&filetype)
    call vista#toc#Run()
  else
    let executive = vista#GetExplicitExecutiveOrDefault()
    call vista#executive#{executive}#Execute(v:false, v:true, v:false)
  endif
endfunction

function! vista#sidebar#IsOpen() abort
  return bufwinnr('__vista__') != -1
endfunction

function! vista#sidebar#ToggleFocus() abort
  if !exists('g:vista') || g:vista.winnr() == -1
    call vista#sidebar#Open()
    return
  endif
  let winnr = g:vista.winnr()
  if winnr != winnr()
    execute winnr.'wincmd w'
  else
    call vista#source#GotoWin()
  endif
endfunction

function! vista#sidebar#Toggle() abort
  if vista#sidebar#IsOpen()
    call vista#sidebar#Close()
  else
    call vista#sidebar#Open()
  endif
endfunction
