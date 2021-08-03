" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

" If we use ftplugin/vista.vim, ftplugin/vista_kind.vim, etc, everytime we'll
" need this:
"
" No usual did_ftplugin check here
"
" So we could just use a function to set the buffer local settings.

function! vista#ftplugin#Set() abort
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

  setlocal foldmethod=expr
  setlocal foldexpr=vista#fold#Expr()
  setlocal foldtext=vista#fold#Text()

  if !vista#statusline#ShouldDisable()
    let &l:statusline = vista#statusline#()
  endif

  if !g:vista_no_mappings
    nnoremap <buffer> <silent> q    :close<CR>
    nnoremap <buffer> <silent> <CR> :<c-u>call vista#cursor#FoldOrJump()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse>
                                  \ :<c-u>call vista#cursor#FoldOrJump()<CR>
    nnoremap <buffer> <silent> s    :<c-u>call vista#Sort()<CR>
    nnoremap <buffer> <silent> p    :<c-u>call vista#cursor#TogglePreview()<CR>
  endif

  augroup VistaCursor
    autocmd!
    if g:vista_echo_cursor
      autocmd CursorMoved <buffer> call vista#cursor#ShowDetailWithDelay()
    endif
    autocmd BufLeave <buffer> call vista#floating#Close()
  augroup END

  if !exists('#VistaMOF')
    call vista#autocmd#InitMOF()
  endif
endfunction
