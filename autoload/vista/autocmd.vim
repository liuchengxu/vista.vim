" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:registered = []

function! s:ClearOtherEvents(group) abort
  for augroup in s:registered
    if augroup != a:group && exists('#'.augroup)
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

  call s:ClearOtherEvents(a:group_name)

  if index(s:registered, a:group_name) == -1
    call add(s:registered, a:group_name)
  endif

  let s:ApplyAutoUpdate = a:AUF

  if exists('#'.a:group_name)
    let group = ''
    redir => group
    silent execute 'autocmd' a:group_name
    redir END
    if len(split(group, '\n')) > 1
      return
    endif
  endif

  execute 'augroup' a:group_name
    autocmd!

    autocmd WinEnter,WinLeave __vista__ call vista#statusline#RenderOnWinEvent()

    " BufReadPost is needed for reloading the current buffer if the file
    " was changed by an external command;
    autocmd BufWritePost,BufReadPost,CursorHold *
          \ call s:GenericAutoUpdate(fnamemodify(expand('<afile>'), ':p'))
  augroup END
endfunction


function! vista#autocmd#InitMOF() abort
  augroup VistaMOF
    autocmd!
    autocmd CursorMoved * call vista#cursor#FindNearestMethodOrFunction()
  augroup END
endfunction
