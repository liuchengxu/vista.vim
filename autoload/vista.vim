" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" Skip special buffers, filetypes.
function! vista#ShouldSkip() abort
  let blacklist = ['vista', 'nerdtree', 'startify', 'tagbar']

  return !empty(&buftype)
        \ || empty(&filetype)
        \ || index(blacklist, &filetype) > -1
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
        return vista#util#Error('Invalid args. expected: Vista!!')
      endif
    else
      return vista#util#Error('Invalid args. expected: Vista![!]')
    endif
  endif

  if a:0 == 0
    call vista#sidebar#Open()
    return
  endif

  let [bufnr, winnr, fname, fpath] = [bufnr('%'), winnr(), expand('%'), expand('%:p')]

  if a:0 == 1
    if a:1 == 'coc' || a:1 == 'ctags'
      call vista#source#Update(bufnr, winnr, fname, fpath)
      call vista#executive#{a:1}#Execute(v:false, v:true)
    elseif a:1 == 'finder'
      call vista#finder#fzf#Run('coc')
    else
      return vista#util#Error("Invalid args. expected: Vista [EXECUTIVE | finder]")
    endif
  elseif a:0 == 2
    if a:1 !=# 'finder'
      return vista#util#Error("Invalid args. expected: Vista finder [EXECUTIVE]")
    endif
    call vista#finder#fzf#Run(a:2)
    return
  else
    return vista#util#Error("Too many arguments for Vista")
  endif
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

function! vista#SetStatusLine() abort
  let &l:statusline = vista#statusline()
endfunction
