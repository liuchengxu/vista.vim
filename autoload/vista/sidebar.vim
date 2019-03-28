" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:NewWindow() abort
  let position = get(g:, 'vista_sidebar_position', 'vertical botright')
  let width = get(g:, 'vista_sidebar_width', 30)
  let open = position.' '.width.'new'
  silent execute open '__vista__'
  setlocal filetype=vista

  " FIXME when to delete?
  if has_key(t:vista.source, 'fpath')
    let w:first_line_hi_id = matchaddpos('MoreMsg', [1])
  endif
endfunction

" Reload vista buffer given the unrendered data
function! vista#sidebar#Reload(data) abort
  " May be triggered by autocmd event sometimes
  " e.g., unsupported filetypes for ctags or no related language servers.
  if empty(a:data)
    return
  endif

  " FIXME may opening a new tab
  if !has_key(t:vista, 'bufnr')
    return
  endif

  let winnr = bufwinnr(t:vista.bufnr)

  " Abort if can't find vista window
  if winnr == -1
    return
  endif

  let switch_in = winnr() != winnr

  if switch_in
    noautocmd execute winnr."wincmd w"
  endif

  let rendered = vista#viewer#Render(a:data)
  call vista#util#SetBufline(t:vista.bufnr, rendered)

  if switch_in
    wincmd p
  endif
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
    let winnr = bufwinnr(t:vista.bufnr)
    if winnr ==  -1
      silent execute 'botright vsplit +buffer'.t:vista.bufnr
      vertical resize 30
    else
      if winnr() != winnr
        noautocmd execute winnr."wincmd w"
      endif
    endif
  endif

  if exists('#User#VistaWinOpen')
    doautocmd User VistaWinOpen
  endif

  call vista#util#SetBufline(t:vista.bufnr, a:rows)

  if !get(g:, 'vista_stay_on_open', 1)
    wincmd p
  endif
endfunction

function! vista#sidebar#Close() abort
  if exists('t:vista.bufnr')
    silent execute  t:vista.bufnr.'bwipe!'
    unlet t:vista.bufnr
  endif

  if exists('t:vista.winnr')
    let winnr = t:vista.winnr
    noautocmd execute winnr.'wincmd w'
    if winnr() == winnr
      close!
      let pos = t:vista.pos
      execute pos[-1]
      noautocmd execute pos[1].'wincmd w'
      call winrestview(pos[0])
    endif
    unlet t:vista.winnr
  endif

  call s:ClearAugroups('VistaCoc', 'VistaCtags')
endfunction

function! s:ClearAugroups(...) abort
  for aug in a:000
    if exists('#'.aug)
      execute 'autocmd!' aug
    endif
  endfor
endfunction

function! vista#sidebar#CloseIfVisible() abort
  let winnr = bufwinnr('__vista__')
  if winnr != -1
    execute winnr.'close!'
  endif
endfunction

function! s:GetExplicitExecutive() abort
  let ft = &filetype

  if exists('g:vista_'.ft.'_executive')
    execute 'return' 'g:vista_'.ft.'_executive'
  endif

  if exists('g:vista_executive_for') && has_key(g:vista_executive_for, ft)
    return g:vista_executive_for[ft]
  endif

  return v:null
endfunction

function! vista#sidebar#Open() abort
  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]
  call vista#source#Update(bufnr, winnr, fname, fpath)

  let explicit_executive = s:GetExplicitExecutive()

  if explicit_executive isnot# v:null
    let executive = explicit_executive
  else
    let executive = get(g:, 'vista_default_executive', 'ctags')
  endif

  call vista#executive#{executive}#Execute(v:false, v:true, v:false)
endfunction

function! s:IsVisible() abort
  return bufwinnr('__vista__') != -1
endfunction

function! vista#sidebar#Toggle() abort
  if s:IsVisible()
    call vista#sidebar#Close()
  else
    call vista#sidebar#Open()
  endif
endfunction
