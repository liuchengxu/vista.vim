" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Could use the cached data?
function! s:IsUsable(cache, fpath) abort
  return !empty(a:cache)
        \ && has_key(a:cache, a:fpath)
        \ && getftime(a:fpath) == a:cache.ftime
        \ && !getbufvar(a:cache.bufnr, '&mod')
endfunction

" Try other alternative executives when the data given by the specified one is empty.
" Return v:true if some alternative brings us some data, or else v:false.
function! s:TryAlternatives(tried, fpath) abort
  " TODO when more executives added allow configuring this list
  let executives = get(g:, 'vista_finder_alternative_executives', g:vista#executives)

  if empty(executives)
    return v:false
  endif

  let alternatives = filter(copy(executives), 'v:val != a:tried')

  for alternative in alternatives
    let s:data = vista#executive#{alternative}#Run(a:fpath)
    if !empty(s:data)
      let s:cur_executive = alternative
      let s:using_alternative = v:true
      return v:true
    endif
  endfor

  return v:false
endfunction

function! vista#finder#GetSymbols(...) abort
  let executive = a:0 > 0 ? a:1 : get(g:, 'vista_default_executive', 'ctags')

  if index(g:vista#executives, executive) == -1
    call vista#error#InvalidExecutive(executive)
    return
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
    let t:vista.skip_set_provider = v:true
    " In this case, we normally want to run synchronously IMO.
    let s:data = vista#executive#{executive}#Run(fpath)
  endif

  let s:cur_executive = executive
  let s:using_alternative = v:false

  if empty(s:data) && !s:TryAlternatives(executive, fpath)
    return [v:null, s:cur_executive, s:using_alternative]
  endif

  return [s:data, s:cur_executive, s:using_alternative]
endfunction

" Find the maximum length of each column of items to be displayed
function! s:FindColumnsMaxLen(raw_items) abort
  let [max_len_kind, max_len_lnum_and_text] = [-1, -1]

  for [kind, v] in items(a:raw_items)
    let kind_len = strwidth(kind)
    if kind_len > max_len_kind
      let max_len_kind = kind_len
    endif

    for item in v
      let lnum_and_text = printf('%s:%s', item.lnum, item.text)
      let len_lnum_and_text = strwidth(lnum_and_text)
      if len_lnum_and_text > max_len_lnum_and_text
        let max_len_lnum_and_text = len_lnum_and_text
      endif
    endfor
  endfor

  return [max_len_kind, max_len_lnum_and_text]
endfunction

" Prepare source for fzf, skim finder
function! vista#finder#PrepareSource(raw_items) abort
  let source = []

  let [max_len_kind, max_len_lnum_and_text] = s:FindColumnsMaxLen(a:raw_items)

  for [kind, v] in items(a:raw_items)
    let icon = vista#renderer#IconFor(kind)
    for item in v
      let line = t:vista.source.line_trimmed(item.lnum)
      let lnum_and_text = printf('%s:%s', item.lnum, item.text)
      let row = printf('%s %s%s  [%s]%s  %s',
            \ icon,
            \ lnum_and_text, repeat(' ', max_len_lnum_and_text- strwidth(lnum_and_text)),
            \ kind, repeat(' ', max_len_kind - strwidth(kind)),
            \ line)
      call add(source, row)
    endfor
  endfor

  return source
endfunction

" Prepare opts for fzf#run(fzf#wrap(opts))
function! vista#finder#PrepareOpts(source, prompt) abort
  let opts = {
          \ 'source': a:source,
          \ 'sink': function('vista#finder#fzf#sink'),
          \ 'options': ['--prompt', a:prompt] + get(g:, 'vista_fzf_opt', []),
          \ }

  if exists('g:vista_fzf_preview')
    let preview_opts = call('fzf#vim#with_preview', g:vista_fzf_preview).options
    let preview_opts[-1] = preview_opts[-1][0:-3] . t:vista.source.fpath . (g:vista#renderer#enable_icon ? ':{2}' : ':{1}')
    call extend(opts.options, preview_opts)
  endif

  return opts
endfunction

" Actually call fzf#run() with a highlighter given the opts
function! vista#finder#RunFZFOrSkim(apply_run) abort
  echo "\r"

  call a:apply_run()

  " Only add highlights when using nvim, since vim has an issue with the highlight.
  " Ref #139
  if has('nvim')
    call vista#finder#fzf#Highlight()

    " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim
    " Vim Highlight does not work at times
    "
    "  &modifiable is to avoid error in MacVim - E948: Job still running (add ! to end the job)
    " if !has('nvim') && &modifiable
      " edit
    " endif
  endif
endfunction

function! vista#finder#Dispatch(finder, executive) abort
  let finder = empty(a:finder) ? 'fzf' : a:finder
  let executive = empty(a:executive) ? 'ctags' : a:executive
  call vista#finder#{finder}#Run(executive)
endfunction
