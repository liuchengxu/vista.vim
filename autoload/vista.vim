" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:cur_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:vista#executives = map(
      \ split(globpath(s:cur_dir.'/vista/executive', '*'), '\n'),
      \ 'fnamemodify(v:val, ":t:r")')

" Skip special buffers, filetypes.
function! vista#ShouldSkip() abort
  let blacklist = ['vista', 'nerdtree', 'startify', 'tagbar', 'fzf']

  return !empty(&buftype)
        \ || empty(&filetype)
        \ || index(blacklist, &filetype) > -1
endfunction

function! vista#statusline() abort
  let fname = get(t:vista.source, 'fname', '')
  " TODO show current provider
  let provider = get(t:vista, 'provider', '')
  if !empty(provider)
    return '[Vista] '.provider.' %<'.fname
  else
    return '[Vista] %<'.fname
  endif
endfunction

function! vista#SetStatusline() abort
  if has_key(t:vista, 'bufnr')
    call setbufvar(t:vista.bufnr, '&statusline', vista#statusline())
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
    elseif a:1 == 'finder'
      call vista#finder#fzf#Run('coc')
    elseif a:1 == 'finder!'
      call vista#finder#fzf#ProjectRun()
    else
      return vista#error#Expect("Vista [EXECUTIVE | finder]")
    endif
  elseif a:0 == 2
    if a:1 !=# 'finder'
      return vista#error#Expect("Vista finder [EXECUTIVE]")
    endif
    call vista#finder#fzf#Run(a:2)
    return
  else
    return vista#error#("Too many arguments for Vista")
  endif
endfunction
