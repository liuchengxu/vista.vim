" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:is_nvim = has('nvim')

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
    " Do not try nvim_lsp until the related LSP service is registed for nvim_lsp
    " otherwise it may cause the neovim hangs.
    if s:is_nvim && alternative ==# 'nvim_lsp'
      continue
    endif
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
  let executive = a:0 > 0 ? a:1 : g:vista_default_executive

  " 'toc' is a special executive supported by extension, we should use ctags
  " instead for the finder case, ref #255.
  if executive ==# 'toc'
    let executive = 'ctags'
  endif

  if index(g:vista#executives, executive) == -1
    call vista#error#InvalidExecutive(executive)
    return
  endif

  let should_skip = vista#ShouldSkip()
  if should_skip
    let fpath = g:vista.source.fpath
  else
    let fpath = expand('%:p')
  endif

  let cache = vista#executive#{executive}#Cache()
  " FIXME s:IsUsable is actually useless as provider gives s:data.
  if type(cache) == v:t_dict && s:IsUsable(cache, fpath)
    let s:data = cache[fpath]
  else
    if !should_skip
      let [bufnr, winnr, fname] = [bufnr('%'), winnr(), expand('%')]
      call vista#source#Update(bufnr, winnr, fname, fpath)
    endif
    let g:vista.skip_set_provider = v:true
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

function! s:GroupByKindForLSPData(lsp_items) abort
  let s:grouped = {}

  for item in a:lsp_items
    let s:max_len_kind = max([s:max_len_kind, strwidth(item.kind)])

    let lnum_and_text = printf('%s:%s', item.text, item.lnum)
    let s:max_len_lnum_and_text = max([s:max_len_lnum_and_text, strwidth(lnum_and_text)])

    if has_key(s:grouped, item.kind)
      call add(s:grouped[item.kind], item)
    else
      let s:grouped[item.kind] = [item]
    endif
  endfor
endfunction

" Find the maximum length of each column of items to be displayed
function! s:FindColumnBoundary(grouped_data) abort
  for [kind, vals] in items(a:grouped_data)
    let s:max_len_kind = max([s:max_len_kind, strwidth(kind)])

    let sub_max = max(map(copy(vals), 'strwidth(printf(''%s:%s'', v:val.text, v:val.lnum))'))
    let s:max_len_lnum_and_text = max([s:max_len_lnum_and_text, sub_max])
  endfor
endfunction

function! s:IntoRow(icon, kind, item) abort
  let line = g:vista.source.line_trimmed(a:item.lnum)
  let lnum_and_text = printf('%s:%s', a:item.text, a:item.lnum)
  let row = printf('%s%s  [%s]%s  %s',
        \ lnum_and_text, repeat(' ', s:max_len_lnum_and_text- strwidth(lnum_and_text)),
        \ a:kind, repeat(' ', s:max_len_kind - strwidth(a:kind)),
        \ line)

  if a:icon !=# ''
    let row = printf('%s %s', a:icon, row)
  endif

  return row
endfunction

function! s:RenderGroupedData(grouped_data) abort
  let source = []
  for [kind, vals] in items(a:grouped_data)
    let icon = vista#renderer#IconFor(kind)
    let rows = []
    for val in vals
      call add(rows, s:IntoRow(icon, kind, val))
    endfor
    call extend(source, rows)
  endfor
  return source
endfunction

" Prepare source for fzf, skim finder
function! vista#finder#PrepareSource(raw_items) abort
  let [s:max_len_kind, s:max_len_lnum_and_text] = [-1, -1]

  if type(a:raw_items) == v:t_list
    call s:GroupByKindForLSPData(a:raw_items)
    return s:RenderGroupedData(s:grouped)
  else
    call s:FindColumnBoundary(a:raw_items)
    return s:RenderGroupedData(a:raw_items)
  endif
endfunction

" Prepare opts for fzf#run(fzf#wrap(opts))
function! vista#finder#PrepareOpts(source, prompt) abort
  let opts = {
          \ 'source': a:source,
          \ 'sink': function('vista#finder#fzf#sink'),
          \ 'options': ['--prompt', a:prompt, '--nth', '..-2', '--delimiter', ':'] + get(g:, 'vista_fzf_opt', []),
          \ }

  if len(g:vista_fzf_preview) > 0
    let idx = 0
    let opt_preview_window_processed = v:false
    while idx < len(g:vista_fzf_preview)
      if g:vista_fzf_preview[idx] =~# '^\(left\|up\|right\|down\)'
        let g:vista_fzf_preview[idx] = g:vista_fzf_preview[idx] . ':+{-1}-5'
        let opt_preview_window_processed = v:true
      endif
      let idx = idx + 1
    endwhile
    if !opt_preview_window_processed
      call extend(g:vista_fzf_preview, ['right:+{-1}-5'])
    endif
    let preview_opts = call('fzf#vim#with_preview', g:vista_fzf_preview).options

    if has('win32')
      " keeping old code around since we are not sure if / how preview works on windows
      let preview_opts[-1] = preview_opts[-1][0:-3] . g:vista.source.fpath . (g:vista#renderer#enable_icon ? ':{2}' : ':{1}')
    else
      let object_name_index = g:vista#renderer#enable_icon ? '3' : '2'
      let extract_line_number = printf(':$(echo {%s})', object_name_index)
      let preview_opts[-1] = preview_opts[-1][0:-3] . fnameescape(g:vista.source.fpath) . extract_line_number
    endif

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

function! vista#finder#Dispatch(bang, finder, executive) abort
  let finder = empty(a:finder) ? 'fzf' : a:finder
  if empty(a:executive)
    let executive = vista#GetExplicitExecutiveOrDefault()
  else
    let executive = a:executive
  endif
  if a:bang
    call vista#finder#{finder}#ProjectRun(executive)
  else
    call vista#finder#{finder}#Run(executive)
  endif
endfunction
