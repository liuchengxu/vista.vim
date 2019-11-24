" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:cur_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! vista#FindItemsUnderDirectory(dir) abort
  return map(split(globpath(a:dir, '*'), '\n'), 'fnamemodify(v:val, '':t:r'')')
endfunction

let g:vista#finders = vista#FindItemsUnderDirectory(s:cur_dir.'/vista/finder')
let g:vista#executives = vista#FindItemsUnderDirectory(s:cur_dir.'/vista/executive')

" Skip special buffers, filetypes.
function! vista#ShouldSkip() abort
  let blacklist = ['vista', 'vista_kind', 'nerdtree', 'startify', 'tagbar', 'fzf', 'gitcommit']

  return !empty(&buftype)
        \ || empty(&filetype)
        \ || index(blacklist, &filetype) > -1
endfunction

" Ignore some kinds of tags/symbols which is done at the parser step.
function! vista#ShouldIgnore(kind) abort
  return exists('g:vista_ignore_kinds') && index(g:vista_ignore_kinds, a:kind) != -1
endfunction

function! vista#SupportToc() abort
  return &filetype ==# 'markdown' || &filetype ==# 'rst'
endfunction

function! vista#SetProvider(provider) abort
  if get(t:vista, 'skip_set_provider', v:false)
    let t:vista.skip_set_provider = v:false
    return
  endif
  let t:vista.provider = a:provider
  call vista#statusline#Render()
endfunction

function! vista#OnExecute(provider, AUF) abort
  call vista#SetProvider(a:provider)
  call vista#autocmd#Init('Vista'.vista#util#ToCamelCase(a:provider), a:AUF)
endfunction

" call Run in the window win unsilently, unlike win_execute() which uses
" silent by default.
"
" CocAction only fetch symbols for current document, no way for specify the other at the moment.
" workaround for #52
"
" see also #71
function! vista#WinExecute(winnr, Run, ...) abort
  if winnr() != a:winnr
    noautocmd execute a:winnr.'wincmd w'
    let l:switch_back = 1
  endif

  call call(a:Run, a:000)

  if exists('l:switch_back')
    noautocmd wincmd p
  endif
endfunction

" Sort the items under some kind alphabetically.
function! vista#Sort() abort
  if !has_key(t:vista, 'sort')
    let t:vista.sort = v:true
  else
    let t:vista.sort = !t:vista.sort
  endif

  let cache = vista#executive#{t:vista.provider}#Cache()

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

function! s:GetExplicitExecutive() abort
  let ft = &filetype

  if exists('g:vista_'.ft.'_executive')
    execute 'return' 'g:vista_'.ft.'_executive'
  endif

  if exists('g:vista_executive_for') && has_key(g:vista_executive_for, ft)
    return g:vista_executive_for[ft]
  endif

  return v:null
endfunction

function! vista#GetExplicitExecutiveOrDefault() abort
  let explicit_executive = s:GetExplicitExecutive()

  if explicit_executive isnot# v:null
    let executive = explicit_executive
  else
    let executive = get(g:, 'vista_default_executive', 'ctags')
  endif

  return executive
endfunction

function! vista#GenericCloseOverlay() abort
  if exists('*nvim_open_win')
    call vista#floating#Close()
  elseif exists('*popup_create')
    call vista#popup#Close()
  endif
endfunction

" Used for running vista.vim on startup
function! vista#RunForNearestMethodOrFunction() abort
  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]
  call vista#source#Update(bufnr, winnr, fname, fpath)
  let executive = get(g:, 'vista_default_executive', 'ctags')
  call vista#executive#{executive}#Execute(v:false, v:false)

  if !exists('#VistaMOF')
    call vista#autocmd#InitMOF()
  endif
endfunction

" Main entrance to interact with vista.vim
function! vista#(bang, ...) abort

  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]

  call vista#source#Update(bufnr, winnr, fname, fpath)

  if a:bang
    if a:0 == 0
      call vista#sidebar#Close()
      return
    elseif a:0 == 1
      if a:1 ==# '!'
        let t:vista.lnum = line('.')
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
    if index(g:vista#executives, a:1) > -1
      call vista#executive#{a:1}#Execute(v:false, v:true)
      let t:vista.lnum = line('.')
    elseif a:1 ==# 'finder'
      call vista#finder#Dispatch('', '')
    elseif a:1 ==# 'finder!'
      call vista#finder#fzf#ProjectRun()
    elseif a:1 ==# 'toc'
      if vista#SupportToc()
        call vista#extension#{&filetype}#Execute(v:false, v:true)
      else
        return vista#error#For('Vista toc', &filetype)
      endif
    elseif a:1 ==# 'focus'
      call vista#sidebar#ToggleFocus()
    elseif a:1 ==# 'show'
      if vista#sidebar#IsVisible()
        call vista#cursor#ShowTag()
      else
        call vista#sidebar#Open()
        let t:vista.lnum = line('.')
      endif
    elseif a:1 ==# 'info'
      call vista#debugging#Info()
    elseif a:1 ==# 'info+'
      call vista#debugging#InfoToClipboard()
    else
      return vista#error#Expect('Vista [finder] [EXECUTIVE]')
    endif
  elseif a:0 == 2
    if a:1 !=# 'finder'
      return vista#error#Expect('Vista finder [EXECUTIVE]')
    endif
    let finder_args_reg = '^\('.join(g:vista#finders, '\|').'\):\('.join(g:vista#executives, '\|').'\)$'
    if stridx(a:2, ':') > -1
      if a:2 =~? finder_args_reg
        let matched = matchlist(a:2, finder_args_reg)
        let finder = matched[1]
        let executive = matched[2]
      else
        return vista#error#Expect('Vista finder [FINDER|EXECUTIVE|FINDER:EXECUTIVE]')
      endif
    else
      if index(g:vista#finders, a:2) > -1
        let finder = a:2
        let executive = ''
      elseif index(g:vista#executives, a:2) > -1
        let finder = ''
        let executive = a:2
      else
        return vista#error#Expect('Vista finder [FINDER|EXECUTIVE|FINDER:EXECUTIVE]')
      endif
    endif
    call vista#finder#Dispatch(finder, executive)
    return
  else
    return vista#error#('Too many arguments for Vista')
  endif
endfunction
