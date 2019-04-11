" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:cur_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:vista#executives = map(
      \ split(globpath(s:cur_dir.'/vista/executive', '*'), '\n'),
      \ 'fnamemodify(v:val, '':t:r'')')

" Skip special buffers, filetypes.
function! vista#ShouldSkip() abort
  let blacklist = ['vista', 'vista_kind', 'nerdtree', 'startify', 'tagbar', 'fzf']

  return !empty(&buftype)
        \ || empty(&filetype)
        \ || index(blacklist, &filetype) > -1
endfunction

function! vista#SetProvider(provider) abort
  let t:vista.provider = a:provider
  call vista#statusline#Render()
endfunction

function! vista#OnExecute(provider, AUF) abort
  call vista#SetProvider(a:provider)
  call vista#autocmd#Init('Vista'.vista#util#ToCamelCase(a:provider), a:AUF)
endfunction

function! vista#RunForNearestMethodOrFunction() abort
  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]
  call vista#source#Update(bufnr, winnr, fname, fpath)
  let executive = get(g:, 'vista_default_executive', 'ctags')
  call vista#executive#{executive}#Execute(v:false, v:false)

  if !exists('#VistaMOF')
    call vista#autocmd#InitMOF()
  endif
endfunction

function! vista#(bang, ...) abort
  if a:bang
    if a:0 == 0
      call vista#sidebar#Close()
      return
    elseif a:0 == 1
      if a:1 ==# '!'
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

  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]

  if a:0 == 1
    if index(g:vista#executives, a:1) > -1
      call vista#source#Update(bufnr, winnr, fname, fpath)
      call vista#executive#{a:1}#Execute(v:false, v:true)
    elseif a:1 ==# 'finder'
      call vista#finder#fzf#Run('coc')
    elseif a:1 ==# 'finder!'
      call vista#finder#fzf#ProjectRun()
    elseif a:1 ==# 'toc'
      if &filetype ==# 'markdown'
        call vista#source#Update(bufnr, winnr, fname, fpath)
        call vista#extension#markdown#Execute(v:false, v:true)
      else
        return vista#error#For('Vista toc', 'markdown')
      endif
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
    call vista#finder#fzf#Run(a:2)
    return
  else
    return vista#error#('Too many arguments for Vista')
  endif
endfunction
