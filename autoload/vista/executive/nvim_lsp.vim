" Copyright (c) 2019 Alvaro Muñoz
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let g:vista_executive_nvim_lsp_reload_only = v:false
let g:vista_executive_nvim_lsp_should_display = v:false
let g:vista_executive_nvim_lsp_fetching = v:true

function! s:AutoUpdate(fpath) abort
  let g:vista_executive_nvim_lsp_reload_only = v:true
  call s:RunAsync()
endfunction

function! s:Run() abort
  if !has('nvim-0.5')
    return
  endif
  call s:RunAsync()
  while g:vista_executive_nvim_lsp_fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! vista#executive#nvim_lsp#SetData(data) abort
  let s:data = a:data
endfunction

function! s:RunAsync() abort
  if !has('nvim-0.5')
    return
  endif
  call vista#SetProvider(s:provider)
  lua << EOF
    local params = vim.lsp.util.make_position_params()
    local callback = function(_, _, result)
        if not result then return end
        vim.g.vista_executive_nvim_lsp_fetching = false
        data = vim.fn['vista#renderer#LSPPreprocess'](result)
        vim.fn['vista#executive#nvim_lsp#SetData'](data)
        if next(data) ~= nil then
          res = vim.fn['vista#renderer#LSPProcess'](data, vim.g.vista_executive_nvim_lsp_reload_only, vim.g.vista_executive_nvim_lsp_should_display)
          vim.g.vista_executive_nvim_lsp_reload_only = res[1]
          vim.g.vista_executive_nvim_lsp_should_display = res[2]
        end
    end
    vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, callback)
EOF
endfunction

function! vista#executive#nvim_lsp#Run(_fpath) abort
  return s:Run()
endfunction

function! vista#executive#nvim_lsp#RunAsync() abort
  call s:RunAsync()
endfunction

function! vista#executive#nvim_lsp#Execute(bang, should_display, ...) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let t:vista.silent = v:false
  let g:vista_executive_nvim_lsp_should_display = a:should_display

  if a:bang
    return s:Run()
  else
    call s:RunAsync()
  endif
endfunction

function! vista#executive#nvim_lsp#Cache() abort
  return get(s:, 'data', {})
endfunction
