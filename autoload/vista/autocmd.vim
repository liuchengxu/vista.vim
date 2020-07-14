" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:registered = []
let s:update_timer = -1
let s:did_open = []
let s:last_event = []
let s:did_buf_enter = []

function! s:ClearOtherEvents(group) abort
  for augroup in s:registered
    if augroup != a:group && exists('#'.augroup)
      execute 'autocmd!' augroup
    endif
  endfor
endfunction

function! s:OnBufEnter(bufnr, fpath) abort
  if index(s:did_buf_enter, a:bufnr) == -1
    call add(s:did_buf_enter, a:bufnr)
    " Only ignore the first BufEnter event for a new buffer
    "
    " When reading a new buffer, BufReadPost and BufEnter will both be
    " triggered for the same buffer, therefore BufEnter is needless and might
    " be problematic.
    if s:last_event == ['BufReadPost', a:bufnr]
      call vista#Debug('ignored the first event.BufEnter for bufnr '.a:bufnr.' because event.BufReadPost was just triggered for the same buffer')
      return
    endif
  endif

  call vista#Debug('event.BufEnter', a:bufnr, a:fpath)
  call s:GenericAutoUpdate('BufEnter', a:bufnr, a:fpath)
endfunction

function! s:OnBufDelete(bufnr) abort
  let idx = index(s:did_open, a:bufnr)
  if idx != -1
    unlet s:did_open[idx]
  endif
  let idx = index(s:did_buf_enter, a:bufnr)
  if idx != -1
    unlet s:did_buf_enter[idx]
  endif
endfunction

function! s:GenericAutoUpdate(event, bufnr, fpath) abort
  if vista#ShouldSkip()
    return
  endif

  call vista#Debug('event.'.a:event. ' processing auto update for buffer '. a:bufnr)
  let [bufnr, winnr, fname] = [a:bufnr, winnr(), expand('%')]

  call vista#source#Update(bufnr, winnr, fname, a:fpath)

  call s:ApplyAutoUpdate(a:fpath)
endfunction

function! s:TriggerUpdate(event, bufnr, fpath) abort
  if s:last_event == [a:event, a:bufnr]
    call vista#Debug('same event for bufnr '.a:bufnr.' was just triggered, ignored for this one')
    return
  endif

  let s:last_event = [a:event, a:bufnr]

  call vista#Debug('new last_event:', s:last_event)

  if index(s:did_open, a:bufnr) == -1
    call vista#Debug('tracking new buffer '.a:bufnr)
    call add(s:did_open, a:bufnr)
  endif

  call s:GenericAutoUpdate(a:event, a:bufnr, a:fpath)
endfunction

function! s:AutoUpdateWithDelay(bufnr, fpath) abort
  if !exists('g:vista')
    return
  endif

  if s:update_timer != -1
    call timer_stop(s:update_timer)
    let s:update_timer = -1
  endif

  let g:vista.on_text_changed = 1
  let s:update_timer = timer_start(
        \ g:vista_update_on_text_changed_delay,
        \ { -> s:GenericAutoUpdate('TextChanged|TextChangedI', a:bufnr, a:fpath)}
        \ )
endfunction

function! s:ClearTempData() abort
  for tmp in g:vista.tmps
    if filereadable(tmp)
      call delete(tmp)
    endif
  endfor
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
    if len(split(execute('autocmd '.a:group_name), '\n')) > 1
      return
    endif
  endif

  execute 'augroup' a:group_name
    autocmd!

    " vint: -ProhibitAutocmdWithNoGroup
    autocmd WinEnter,WinLeave __vista__ call vista#statusline#RenderOnWinEvent()

    " BufReadPost is needed for reloading the current buffer if the file
    " was changed by an external command;
    "
    " CursorHold and CursorHoldI event have been removed in order to
    " highlight the nearest tag automatically.

    autocmd BufReadPost  * call s:TriggerUpdate('BufReadPost', +expand('<abuf>'), fnamemodify(expand('<afile>'), ':p'))
    autocmd BufWritePost * call s:TriggerUpdate('BufWritePost', +expand('<abuf>'), fnamemodify(expand('<afile>'), ':p'))
    autocmd BufEnter     * call s:OnBufEnter(+expand('<abuf>'), fnamemodify(expand('<afile>'), ':p'))

    autocmd BufDelete,BufWipeout * call s:OnBufDelete(+expand('<abuf>'))

    autocmd VimLeavePre * call s:ClearTempData()

    if g:vista_update_on_text_changed
      autocmd TextChanged,TextChangedI *
            \ call s:AutoUpdateWithDelay(+expand('<abuf>'), fnamemodify(expand('<afile>'), ':p'))
    endif
  augroup END
endfunction


function! vista#autocmd#InitMOF() abort
  augroup VistaMOF
    autocmd!
    autocmd CursorMoved * call vista#cursor#FindNearestMethodOrFunction()
  augroup END
endfunction
