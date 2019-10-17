" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" No usual did_ftplugin check here

setlocal
  \ nonumber
  \ norelativenumber
  \ nopaste
  \ nomodeline
  \ noswapfile
  \ nocursorline
  \ nocursorcolumn
  \ colorcolumn=
  \ nobuflisted
  \ buftype=nofile
  \ bufhidden=hide
  \ nomodifiable
  \ signcolumn=no
  \ textwidth=0
  \ nolist
  \ winfixwidth
  \ winfixheight
  \ nospell
  \ nofoldenable
  \ foldcolumn=0
  \ nowrap

" Get rid of extra fold dashes when using Vim folding
setlocal fillchars=fold:\ 

setlocal foldmethod=expr
setlocal foldexpr=vista#fold#Expr()
setlocal foldtext=vista#fold#Text()

if !vista#statusline#ShouldDisable()
  let &l:statusline = vista#statusline#()
endif

nnoremap <buffer> <silent> q     :close<CR>
nnoremap <buffer> <silent> s     :<c-u>call vista#Sort()<CR>
nnoremap <buffer> <silent> p     :<c-u>call vista#cursor#TogglePreview()<CR>
nnoremap <buffer> <silent> <CR>  :<c-u>call vista#cursor#FoldOrJump()<CR>
nnoremap <buffer> <silent> <C-N> :<c-u>call vista#jump#NextTopLevel()<CR>
nnoremap <buffer> <silent> <C-P> :<c-u>call vista#jump#PrevTopLevel()<CR>

augroup VistaCursor
  autocmd!
  if get(g:, 'vista_echo_cursor', 1)
    autocmd CursorMoved <buffer> call vista#cursor#ShowDetailWithDelay()
  endif

  autocmd BufLeave <buffer> call vista#floating#Close()
augroup END

if !exists('#VistaMOF')
  call vista#autocmd#InitMOF()
endif
