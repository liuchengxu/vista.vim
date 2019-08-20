" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

let s:cols_layout = {}
let s:aligner = {}

function! s:cols_layout.project_ctags() abort
  let [max_len_scope, max_len_lnum_and_text, max_len_relpath] = [-1, -1, -1]

  for [kind, v] in items(s:data)
    let scope_len = strwidth(kind)
    if scope_len > max_len_scope
      let max_len_scope = scope_len
    endif

    for item in v
      let lnum_and_text = printf('%s:%s', item.lnum, item.text)
      let len_lnum_and_text = strwidth(lnum_and_text)
      if len_lnum_and_text > max_len_lnum_and_text
        let max_len_lnum_and_text = len_lnum_and_text
      endif

      let relpath = item.tagfile
      let len_relpath = strwidth(relpath)
      if len_relpath > max_len_relpath
        let max_len_relpath = len_relpath
      endif
    endfor
  endfor

  return [max_len_scope, max_len_lnum_and_text, max_len_relpath]
endfunction

function! s:aligner.project_ctags() abort
  let source = []

  let [max_len_scope, max_len_lnum_and_text, max_len_relpath] = s:cols_layout.project_ctags()

  for [kind, v] in items(s:data)
    let icon = vista#renderer#IconFor(kind)
    for item in v
      " FIXME handle ctags -R better
      let lnum_and_text = printf('%s:%s', item.lnum, item.text)
      let relpath = item.tagfile
      let row = printf('%s %s%s  [%s]%s  %s%s  %s',
            \ icon,
            \ lnum_and_text, repeat(' ', max_len_lnum_and_text- strwidth(lnum_and_text)),
            \ kind, repeat(' ', max_len_scope - strwidth(kind)),
            \ relpath, repeat(' ', max_len_relpath - strwidth(relpath)),
            \ item.taginfo)
      call add(source, row)
    endfor
  endfor

  return source
endfunction

" Find the maximum length of each column of items to be displayed
function! s:FindMaxLen() abort
  let [max_len_scope, max_len_lnum_and_text] = [-1, -1]

  for [kind, v] in items(s:data)
    let scope_len = strwidth(kind)
    if scope_len > max_len_scope
      let max_len_scope = scope_len
    endif

    for item in v
      let lnum_and_text = printf('%s:%s', item.lnum, item.text)
      let len_lnum_and_text = strwidth(lnum_and_text)
      if len_lnum_and_text > max_len_lnum_and_text
        let max_len_lnum_and_text = len_lnum_and_text
      endif
    endfor
  endfor

  return [max_len_scope, max_len_lnum_and_text]
endfunction

function! s:AlignSource() abort
  let source = []

  let [max_len_scope, max_len_lnum_and_text] = s:FindMaxLen()

  for [kind, v] in items(s:data)
    let icon = vista#renderer#IconFor(kind)
    for item in v
      let line = t:vista.source.line(item.lnum)
      let lnum_and_text = printf('%s:%s', item.lnum, item.text)
      let row = printf('%s %s%s  [%s]%s  %s',
            \ icon,
            \ lnum_and_text, repeat(' ', max_len_lnum_and_text- strwidth(lnum_and_text)),
            \ kind, repeat(' ', max_len_scope - strwidth(kind)),
            \ line)
      call add(source, row)
    endfor
  endfor

  return source
endfunction

function! s:sink(line) abort
  let icon_lnum_tag = split(a:line, '[')[0]
  let items = matchlist(icon_lnum_tag, '\(.*\) \(\d\+\):\(.*\)')
  let lnum = items[2]
  " Trim?!
  let tag = vista#util#Trim(items[3])
  let col = stridx(t:vista.source.line(lnum), tag)
  let col = col == -1 ? 1 : col + 1
  call vista#source#GotoWin()
  call cursor(lnum, col)
  normal! zz
endfunction

" Actually call fzf#run() with a highlighter given the opts
function! s:ApplyRun(opts, Hi) abort
  echo "\r"

  try
    " fzf_colors may interfere custom syntax.
    " Unlet and restore it later.
    if exists('g:fzf_colors')
      let old_fzf_colors = g:fzf_colors
      unlet g:fzf_colors
    endif

    call fzf#run(fzf#wrap(a:opts))
  finally
    if exists('l:old_fzf_colors')
      let g:fzf_colors = old_fzf_colors
    endif
  endtry

  " Only add highlights when using nvim, since vim has an issue with the highlight.
  " Ref #139
  if has('nvim')
    call call(function(a:Hi), [])

    " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim
    " Vim Highlight does not work at times
    "
    "  &modifiable is to avoid error in MacVim - E948: Job still running (add ! to end the job)
    " if !has('nvim') && &modifiable
      " edit
    " endif
  endif
endfunction

function! s:Run(...) abort
  let source = s:AlignSource()
  let prompt = (get(s:, 'using_alternative', v:false) ? '*' : '').s:cur_executive.'> '
  let opts = {
          \ 'source': source,
          \ 'sink': function('s:sink'),
          \ 'options': ['--prompt', prompt] + get(g:, 'vista_fzf_opt', []),
          \ }

  if exists('g:vista_fzf_preview')
    let preview_opts = call('fzf#vim#with_preview', g:vista_fzf_preview).options
    let preview_opts[-1] = preview_opts[-1][0:-3] . t:vista.source.fpath . (g:vista#renderer#enable_icon ? ':{2}' : ':{1}')
    call extend(opts.options, preview_opts)
  endif

  call s:ApplyRun(opts, 's:Highlight')
endfunction

function! s:project_sink(line) abort
  let parts = split(a:line, '\t')
  let lnum = split(parts[0], ':')[0]
  let relpath = parts[2]
  execute 'edit' relpath
  call cursor(lnum, 1)
  normal! zz
endfunction

function! s:ProjectRun(...) abort
  let source = s:aligner.project_ctags()
  let prompt = (get(s:, 'using_alternative', v:false) ? '*' : '').s:cur_executive.'> '
  let opts = {
          \ 'source': source,
          \ 'sink': function('s:project_sink'),
          \ 'options': ['--prompt', prompt] + get(g:, 'vista_fzf_opt', []),
          \ }

  call s:ApplyRun(opts, 's:Highlight')
endfunction

function! s:Highlight() abort
  let icons = join(values(g:vista#renderer#icons), '\|')
  execute 'syntax match FZFVistaIcon' '/'.icons.'/' 'contained'

  syntax match FZFVistaNumber /\s*\zs\d*:\ze\w/ contains=FZFVistaIcon
  syntax match FZFVistaTag    /^[^\[]*\(\[\)\@=/ contains=FZFVistaNumber,FZFVistaIcon
  syntax match FZFVistaScope  /^[^]]*]/ contains=FZFVistaTag,FZFVistaBracket
  syntax match FZFVista /^[^│┌└]*/ contains=FZFVistaBracket,FZFVistaNumber,FZFVistaTag,FZFVistaScope
  syntax match FZFVistaBracket /\[\|\]/ contained

  hi default link FZFVistaIcon     Special
  hi default link FZFVistaBracket  SpecialKey
  hi default link FZFVistaNumber   Number
  hi default link FZFVistaTag      Tag
  hi default link FZFVistaScope    Function
  hi default link FZFVista         Type
endfunction

" TODO workspace symbols
function! vista#finder#fzf#ProjectRun() abort
  let executive = 'ctags'
  let s:data = vista#executive#{executive}#ProjectRun()
  let s:cur_executive = executive

  if empty(s:data)
    return vista#util#Warning('Empty data for finder')
  endif

  call s:ProjectRun()
endfunction

" Optional argument: executive, coc or ctags
" Ctags is the default.
function! vista#finder#fzf#Run(...) abort
  if !exists('*fzf#run')
    call vista#error#Need('fzf')
    return
  endif

  let [s:data, s:cur_executive, s:using_alternative] = call('vista#finder#GetSymbols', a:000)

  if s:data is# v:null
    return vista#util#Warning('Empty data for fzf finder')
  endif

  call s:Run()
endfunction
