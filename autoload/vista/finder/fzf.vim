" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Find the maximum length of each column of items to be displayed
function! s:FindMaxLen() abort
  let [max_len_scope, max_len_lnum_and_text] = [-1, -1]

  let s:num = 0

  for [kind, v] in items(s:data)
    let scope_len = strwidth(kind)
    if scope_len > max_len_scope
      let max_len_scope = scope_len
    endif

    let s:num += len(v)

    for item in v
      let lnum_and_text = printf("%s:%s", item.lnum, item.text)
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
    for item in v
      let line = vista#source#Line(item.lnum)
      let lnum_and_text = printf("%s:%s", item.lnum, item.text)
      let row = printf("%s%s\t[%s]%s\t%s",
            \ lnum_and_text, repeat(' ', max_len_lnum_and_text- strwidth(lnum_and_text)),
            \ kind, repeat(' ', max_len_scope - strwidth(kind)),
            \ line)
      call add(source, row)
    endfor
  endfor

  return source
endfunction

function! s:sink(line) abort
  let lnum = split(a:line)[0]
  call vista#source#GotoWin()
  call cursor(lnum, 1)
  normal! zz
endfunction

function! s:Run(...) abort
  let source = s:AlignSource()
  let opts = {
          \ 'source': source,
          \ 'sink': function('s:sink'),
          \ 'options': '--prompt "('.s:num.') > "',
          \ }

  echo "\r"

  try
    " fzf_colors may interfere custom syntax.
    " Unlet and restore it later.
    if exists('g:fzf_colors')
      let old_fzf_colors = g:fzf_colors
      unlet g:fzf_colors
    endif

    call fzf#run(fzf#wrap(opts))
  finally
    if exists('l:old_fzf_colors')
      let g:fzf_colors = old_fzf_colors
    endif
  endtry

  call s:Highlight()

  " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim
  " Vim Highlight does not work at times
  if !has('nvim')
    edit
  endif
endfunction

function! s:Highlight() abort
  syntax match FZFVistaBracket /\[\|\]/ contained
  syntax match FZFVistaNumber /^\s*\zs\d*:\ze\w/
  syntax match FZFVistaTag    /^\s.*\ze\[/ contains=FZFVistaNumber
  syntax match FZFVistaScope  /^\s.*\[.*\]\ze\s/ contains=FZFVistaTag,FZFVistaBracket
  syntax match FZFVista /^.*$/ contains=FZFVistaBracket,FZFVistaNumber,FZFVistaTag,FZFVistaScope

  hi default link FZFVistaBracket  SpecialKey
  hi default link FZFVistaNumber   Number
  hi default link FZFVistaTag      Tag
  hi default link FZFVistaScope    Function
  hi default link FZFVista         Type
endfunction

" Could use the cached data?
function! s:IsUsable(cache, fpath) abort
  return !empty(a:cache)
        \ && has_key(a:cache, a:fpath)
        \ && getftime(a:fpath) == a:cache.ftime
        \ && !getbufvar(a:cache.bufnr, '&mod')
endfunction

" Optional argument: executive, coc or ctags
" Ctags is the default.
function! vista#finder#fzf#Run(...) abort
  " TODO when more executives added allow configuring this list
  let executives = ['ctags', 'coc'] 
  if a:0 > 0
    let executive = a:1
  else
    let executive = 'ctags'
  endif

  let cache = vista#executive#{executive}#Cache()
  let skip = vista#ShouldSkip()
  if skip
    let t:vista.source = get(t:vista, 'source', {})
    let fpath = t:vista.source.fpath 
  else
    let fpath = expand('%:p')
  endif

  if s:IsUsable(cache, fpath)
    let s:data = cache[fpath]
  else
    if !skip      
      let [bufnr, winnr, fname] = [bufnr('%'), winnr(), expand('%')]
      call vista#source#Update(bufnr, winnr, fname, fpath)
    endif
    " In this case, we normally want to run synchronously IMO.
    let s:data = vista#executive#{executive}#Run(fpath)
  endif

  if empty(s:data)
    let i = index(executives, executive)
    let _ = remove(executives, i)
    let s:data = vista#executive#{executives[0]}#Run(fpath)
    if empty(s:data)
      vista#util#Warning("Empty data for finder")
    endif
  endif

  call s:Run()
endfunction
