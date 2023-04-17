" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:cur_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! vista#FindItemsUnderDirectory(dir) abort
  return map(split(globpath(a:dir, '*'), '\n'), 'fnamemodify(v:val, '':t:r'')')
endfunction

let g:vista#finders = vista#FindItemsUnderDirectory(s:cur_dir.'/vista/finder')
let g:vista#executives = vista#FindItemsUnderDirectory(s:cur_dir.'/vista/executive')
let g:vista#extensions = vista#FindItemsUnderDirectory(s:cur_dir.'/vista/extension')

let s:ignore_list = ['vista', 'vista_kind', 'nerdtree', 'startify', 'tagbar', 'fzf', 'gitcommit', 'coc-explorer']

" Skip special buffers, filetypes.
function! vista#ShouldSkip() abort
  if exists('g:vista.skip_once_flag') && g:vista.skip_once_flag
    let g:vista.skip_once_flag = v:false
    return v:true
  else
    return !empty(&buftype)
          \ || empty(&filetype)
          \ || index(s:ignore_list, &filetype) > -1
  endif
endfunction

" Ignore some kinds of tags/symbols which is done at the parser step.
function! vista#ShouldIgnore(kind) abort
  return exists('g:vista_ignore_kinds') && index(g:vista_ignore_kinds, a:kind) != -1
endfunction

function! vista#SetProvider(provider) abort
  if get(g:vista, 'skip_set_provider', v:false)
    let g:vista.skip_set_provider = v:false
    return
  endif
  let g:vista.provider = a:provider
  call vista#statusline#Render()
endfunction

function! vista#OnExecute(provider, AUF) abort
  call vista#SetProvider(a:provider)
  call vista#autocmd#Init('Vista'.vista#util#ToCamelCase(a:provider), a:AUF)
endfunction

" Sort the items under some kind alphabetically.
function! vista#Sort() abort
  if !has_key(g:vista, 'sort')
    let g:vista.sort = v:true
  else
    let g:vista.sort = !g:vista.sort
  endif

  let cache = vista#executive#{g:vista.provider}#Cache()

  let cur_pos = getpos('.')

  call vista#sidebar#Reload(cache)

  if cur_pos != getpos('.')
    call setpos('.', cur_pos)
  endif
endfunction

" coc.nvim returns no symbols if you just send the request on the event.
" We use a delayed update instead.
" Maybe also useful for the other LSP clients.
function! vista#AutoUpdateWithDelay(Fn, Args) abort
  call timer_start(30, { -> call(a:Fn, a:Args) })
endfunction

function! vista#GetExplicitExecutive(filetype) abort
  if exists('g:vista_'.a:filetype.'_executive')
    return g:vista_{a:filetype}_executive
  endif

  if has_key(g:vista_executive_for, a:filetype)
    return g:vista_executive_for[a:filetype]
  endif

  return v:null
endfunction

function! vista#GetExplicitExecutiveOrDefault() abort
  let explicit_executive = vista#GetExplicitExecutive(&filetype)

  if explicit_executive isnot# v:null
    let executive = explicit_executive
  else
    let executive = g:vista_default_executive
  endif

  return executive
endfunction

function! s:TryInitializeVista() abort
  if !exists('g:vista')
    call vista#init#Api()
  endif
endfunction

call s:TryInitializeVista()

" TODO: vista is designed to have an instance per tab, but it does not work as
" expected now.
" augroup VistaInitialize
  " autocmd!
  " ++once needs 8.1.1113, it's safer but requires newer vim.
  " autocmd TabNew * ++once call s:TryInitializeVista()
" augroup END

" Used for running vista.vim on startup
function! vista#RunForNearestMethodOrFunction() abort
  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]
  call vista#source#Update(bufnr, winnr, fname, fpath)
  call vista#executive#{g:vista_default_executive}#Execute(v:false, v:false)
  let g:__vista_initial_run_find_nearest_method = 1

  if !exists('#VistaMOF')
    call vista#autocmd#InitMOF()
  endif
endfunction

let s:logging_enabled = exists('g:vista_log_file') && !empty(g:vista_log_file)

function! vista#Debug(...) abort
  if s:logging_enabled
    call writefile([strftime('%Y-%m-%d %H:%M:%S ').json_encode(a:000)], g:vista_log_file, 'a')
  endif
endfunction

function! s:HandleSingleArgument(arg) abort
  if index(g:vista#executives, a:arg) > -1
    call vista#executive#{a:arg}#Execute(v:false, v:true)
    let g:vista.lnum = line('.')
  elseif a:arg ==# 'finder'
    call vista#finder#Dispatch(v:false, '', '')
  elseif a:arg ==# 'finder!'
    call vista#finder#Dispatch(v:true, '', '')
  elseif a:arg ==# 'toc'
    if vista#toc#IsSupported(&filetype)
      call vista#toc#Run()
    else
      return vista#error#For('Vista toc', &filetype)
    endif
  elseif a:arg ==# 'focus'
    call vista#sidebar#ToggleFocus()
  elseif a:arg ==# 'show'
    if vista#sidebar#IsOpen()
      call vista#cursor#ShowTag()
    else
      call vista#sidebar#Open()
      let g:vista.lnum = line('.')
    endif
  elseif a:arg ==# 'info'
    call vista#debugging#Info()
  elseif a:arg ==# 'info+'
    call vista#debugging#InfoToClipboard()
  else
    return vista#error#Expect('Vista [finder] [EXECUTIVE]')
  endif
endfunction

function! s:HandleArguments(fst, snd) abort
  if a:fst !~# '^finder'
    return vista#error#Expect('Vista finder[!] [EXECUTIVE]')
  endif
  " Vista finder [finder:executive]
  if stridx(a:snd, ':') > -1
    if !exists('s:finder_args_pattern')
      let s:finder_args_pattern = '^\('.join(g:vista#finders, '\|').'\):\('.join(g:vista#executives, '\|').'\)$'
    endif
    if a:snd =~? s:finder_args_pattern
      let matched = matchlist(a:snd, s:finder_args_pattern)
      let finder = matched[1]
      let executive = matched[2]
    else
      return vista#error#InvalidFinderArgument()
    endif
  else
    " Vista finder [finder]/[executive]
    if index(g:vista#finders, a:snd) > -1
      let finder = a:snd
      let executive = ''
    elseif index(g:vista#executives, a:snd) > -1
      let finder = ''
      let executive = a:snd
    else
      return vista#error#InvalidFinderArgument()
    endif
  endif
  call vista#finder#Dispatch(v:false, finder, executive)
endfunction

" Main entrance to interact with vista.vim
function! vista#(bang, ...) abort
  " `:Vista focus` should be handled before updating the source buffer info.
  if a:0 == 1 && a:1 ==# 'focus'
    call vista#sidebar#ToggleFocus()
    return
  endif

  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]
  let g:vista.source.winid = win_getid()
  call vista#source#Update(bufnr, winnr, fname, fpath)

  if a:bang
    if a:0 == 0
      call vista#sidebar#Close()
      return
    elseif a:0 == 1
      if a:1 ==# '!'
        let g:vista.lnum = line('.')
        call vista#sidebar#Toggle()
        return
      else
        return vista#error#Expect('Vista!!')
      endif
    else
      return vista#error#Expect('Vista![!]')
    endif
  endif

  if a:0 == 0
    call vista#sidebar#Open()
    return
  endif

  if a:0 == 1
    call s:HandleSingleArgument(a:1)
  elseif a:0 == 2
    call s:HandleArguments(a:1, a:2)
  elseif a:0 > 0
    return vista#error#('Too many arguments for Vista')
  endif
endfunction
