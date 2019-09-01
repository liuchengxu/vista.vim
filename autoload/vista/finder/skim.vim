" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:finder = fnamemodify(expand('<sfile>'), ':t:r')

" Actually call skim#run()
function! s:ApplyRun() abort
  try
    " skim_colors may interfere custom syntax.
    " Unlet and restore it later.
    if exists('g:skim_colors')
      let old_skim_colors = g:skim_colors
      unlet g:skim_colors
    endif

    call skim#run(skim#wrap(s:opts))
  finally
    if exists('l:old_skim_colors')
      let g:skim_colors = old_skim_colors
    endif
  endtry
endfunction

function! s:Run(...) abort
  let source = vista#finder#PrepareSource(s:data)
  let using_alternative = get(s:, 'using_alternative', v:false) ? '*' : ''
  let prompt = using_alternative.s:finder.':'.s:cur_executive.'> '

  let s:opts = vista#finder#PrepareOpts(source, prompt)

  call vista#finder#RunFZFOrSkim(function('s:ApplyRun'))
endfunction

" Optional argument: executive, coc or ctags
" Ctags is the default.
function! vista#finder#skim#Run(...) abort
  if !exists('*skim#run')
    return vista#error#Need('https://github.com/lotabout/skim')
  endif

  let [s:data, s:cur_executive, s:using_alternative] = call('vista#finder#GetSymbols', a:000)

  if s:data is# v:null
    return vista#util#Warning('Empty data for skim finder')
  endif

  call s:Run()
endfunction
