" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

let s:finder = fnamemodify(expand('<sfile>'), ':t:r')

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

function! vista#finder#fzf#extract(line) abort
  if g:vista#renderer#enable_icon
    " icon tag:lnum
    let icon_stripped = join(split(a:line)[1:], ' ')
  else
    let icon_stripped = a:line
  end

  " [a-zA-Z:#_.,<>]
  " matching tag can't contain whitespace, but a tag does have a chance to contain whitespace?
  let items = matchlist(icon_stripped, '\([a-zA-Z:#_.,<>]*\):\(\d\+\)')
  let tag = items[1]
  let lnum = items[2]

  return [lnum, tag]
endfunction

" Optional argument: winid for the origin tags window
function! vista#finder#fzf#sink(line, ...) abort
  let [lnum, tag] = vista#finder#fzf#extract(a:line)
  let col = stridx(g:vista.source.line(lnum), tag)
  let col = col == -1 ? 1 : col + 1
  if a:0 > 0
    if win_getid() != a:1
      noautocmd call win_gotoid(a:1)
    endif
  else
    call vista#source#GotoWin()
  endif
  call vista#util#Cursor(lnum, col)
  normal! zz
  call call('vista#util#Blink', get(g:, 'vista_blink', [2, 100]))
endfunction

" Actually call fzf#run() with a highlighter given the opts
function! s:ApplyRun() abort
  try
    " fzf_colors may interfere custom syntax.
    " Unlet and restore it later.
    if exists('g:fzf_colors') && !get(g:, 'vista_keep_fzf_colors', 0)
      let l:old_fzf_colors = g:fzf_colors
      unlet g:fzf_colors
    endif

    call fzf#run(fzf#wrap(s:opts))
  finally
    if exists('l:old_fzf_colors')
      let g:fzf_colors = old_fzf_colors
    endif
  endtry
endfunction

function! s:Run(...) abort
  let source  = vista#finder#PrepareSource(s:data)
  let using_alternative = get(s:, 'using_alternative', v:false) ? '*' : ''
  let prompt = using_alternative.s:finder.':'.s:cur_executive.'> '

  let s:opts = vista#finder#PrepareOpts(source, prompt)

  call vista#finder#RunFZFOrSkim(function('s:ApplyRun'))
endfunction

function! s:project_sink(line) abort
  let parts = split(a:line)
  let lnum = split(parts[1], ':')[0]
  let relpath = parts[3]
  execute 'edit' relpath
  call vista#util#Cursor(lnum, 1)
  normal! zz
endfunction

function! s:ProjectRun(...) abort
  let source = s:aligner.project_ctags()
  let prompt = (get(s:, 'using_alternative', v:false) ? '*' : '').s:cur_executive.'> '
  let s:opts = {
          \ 'source': source,
          \ 'sink': function('s:project_sink'),
          \ 'options': ['--prompt', prompt] + get(g:, 'vista_fzf_opt', []),
          \ }

  call s:ApplyRun()
  if has('nvim')
    call vista#finder#fzf#Highlight()
  endif
endfunction

function! vista#finder#fzf#Highlight() abort
  let groups = ['Character', 'Float', 'Identifier', 'Statement', 'Label', 'Boolean', 'Delimiter', 'Constant', 'String', 'Operator', 'PreCondit', 'Include', 'Conditional', 'PreProc', 'TypeDef',]
  let len_groups = len(groups)

  let icons = values(g:vista#renderer#icons)

  let idx = 0
  let hi_idx = 0

  let icon_groups = []
  for icon in icons
    let cur_group = 'FZFVistaIcon'.idx
    call add(icon_groups, cur_group)
    execute 'syntax match' cur_group '/'.icon.'/' 'contained'
    execute 'hi default link' cur_group groups[hi_idx]
    let hi_idx += 1
    let hi_idx = hi_idx % len_groups
    let idx += 1
  endfor

  execute 'syntax match FZFVistaTag    /\s*.*\(:\d\+\s\)\@=/' 'contains=FZFVistaIcon,'.join(icon_groups, ',')
  execute 'syntax match FZFVistaNumber /^.*\(\s\s\[\)\@=/' 'contains=FZFVistaTag,FZFVistaIcon,'.join(icon_groups, ',')
  syntax match FZFVistaScope  /^.*\]\s\s/ contains=FZFVistaNumber,FZFVistaBracket
  syntax match FZFVista /^[^│┌└]*/ contains=FZFVistaBracket,FZFVistaTag,FZFVistaNumber,FZFVistaScope
  syntax match FZFVistaBracket /\s\s\[\|\]\s\s/ contained

  hi default link FZFVistaBracket  SpecialKey
  hi default link FZFVistaNumber   Number
  hi default link FZFVistaTag      Tag
  hi default link FZFVistaScope    Function
  hi default link FZFVista         Type
endfunction

" Optional argument: executive, coc or ctags
" Ctags is the default.
function! vista#finder#fzf#Run(...) abort
  if g:vista_close_on_fzf_select
    call vista#sidebar#Close()
  endif
  if !exists('*fzf#run')
    return vista#error#Need('https://github.com/junegunn/fzf')
  endif

  let [s:data, s:cur_executive, s:using_alternative] = call('vista#finder#GetSymbols', a:000)

  if s:data is# v:null
    return vista#util#Warning('Empty data for fzf finder')
  endif

  call s:Run()
endfunction

" TODO workspace symbols
function! vista#finder#fzf#ProjectRun(executive) abort
  if a:executive !=? 'ctags'
    return vista#error#('Only ctags supports Vista finder!')
  endif

  let s:data = vista#executive#{a:executive}#ProjectRun()
  let s:cur_executive = a:executive

  if empty(s:data)
    return vista#util#Warning('Empty data for finder')
  endif

  call s:ProjectRun()
endfunction
