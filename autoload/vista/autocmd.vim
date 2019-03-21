" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:registered = []

function! s:ClearOtherEvents() abort
  for augroup in s:registered
    if exists('#'.augroup)
      execute 'autocmd!' augroup
    endif
  endfor
endfunction

function! s:GenericAutoUpdate(fpath) abort
  if vista#ShouldSkip()
    return
  endif

  let [bufnr, winnr, fname] = [bufnr('%'), winnr(), expand('%')]

  call vista#source#Update(bufnr, winnr, fname, a:fpath)

  call s:ApplyAutoUpdate(a:fpath)
endfunction

" Every time we call :Vista foo, we should clear other autocmd events and only
" keep the current one, otherwise there will be multiple autoupdate events
" interacting with other.
function! vista#autocmd#Init(group_name, AUF) abort

  call s:ClearOtherEvents()

  if index(s:registered, a:group_name) == -1
    call add(s:registered, a:group_name)
  endif

  let s:ApplyAutoUpdate = a:AUF

  execute 'augroup' a:group_name
    autocmd!

    autocmd WinEnter,WinLeave __vista__ let &l:statusline = vista#statusline()

    " BufReadPost is needed for reloading the current buffer if the file
    " was changed by an external command;
    autocmd BufWritePost,BufReadPost,CursorHold *
          \ call s:GenericAutoUpdate(fnamemodify(expand('<afile>'), ':p'))
  augroup END
endfunction
