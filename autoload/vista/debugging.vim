" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

function! s:GetAvaliableExecutives() abort
  let avaliable = []

  if exists('*ale#lsp_linter#SendRequest')
    call add(avaliable, 'ale')
  endif

  if exists('*CocAction')
    call add(avaliable, 'coc')
  endif

  if executable('ctags')
    call add(avaliable, 'ctags')
  endif

  if exists('*LanguageClient#textDocument_documentSymbol')
    call add(avaliable, 'lcn')
  endif

  if exists('*lsc#server#userCall')
    call add(avaliable, 'vim_lsc')
  endif

  if exists('*lsp#get_whitelisted_servers')
    call add(avaliable, 'vim_lsp')
  endif

  return avaliable
endfunction

function! s:GetGlobalVariables() abort
  let variable_list = []

  for key in keys(g:)
    if key =~# '^vista'
      call add(variable_list, key)
    endif
  endfor

  " Ignore the variables of types
  call filter(variable_list, 'v:val !~# ''vista#types#''')

  call sort(variable_list)

  return variable_list
endfunction

function! vista#debugging#Info() abort
  let avaliable_executives = string(s:GetAvaliableExecutives())
  let global_variables = s:GetGlobalVariables()

  echohl Type   | echo '    Current FileType: ' | echohl NONE
  echohl Normal | echon &filetype               | echohl NONE
  echohl Type   | echo 'Avaliable Executives: ' | echohl NONE
  echohl Normal | echon avaliable_executives    | echohl NONE
  echohl Type   | echo '    Global Variables:'  | echohl NONE
  for variable in global_variables
    echo '    let g:'.variable.' = '. string(g:[variable])
  endfor
endfunction

function! vista#debugging#InfoToClipboard() abort
  redir => l:output
    silent call vista#debugging#Info()
  redir END

  let @+ = l:output
  echohl Type     | echo '[vista.vim] '               | echohl NONE
  echohl Function | echon 'Vista info'                | echohl NONE
  echohl Normal   | echon ' copied to your clipboard' | echohl NONE
endfunction
