" Copyright (c) 2019 Alvaro Muñoz
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let g:vista_executive_nvim_lsp_reload_only = v:false
let g:vista_executive_nvim_lsp_should_display = v:false
let g:vista_executive_nvim_lsp_fetching = v:true

function! s:AutoUpdate(fpath) abort
  let g:vista_executive_nvim_lsp_reload_only = v:true
  let s:fpath = a:fpath
  call s:RunAsync()
endfunction

function! s:Run() abort
  if !has('nvim-0.5')
    return
  endif
  let g:vista_executive_nvim_lsp_fetching = v:true
  call s:RunAsync()
  while g:vista_executive_nvim_lsp_fetching
    sleep 100m
  endwhile
  return get(s:, 'data', {})
endfunction

function! vista#executive#nvim_lsp#SetData(data) abort
  let s:data = a:data
  " Update cache when new data comes.
  let s:cache = get(s:, 'cache', {})
  let s:cache[s:fpath] = s:data
  let s:cache.ftime = getftime(s:fpath)
  let s:cache.bufnr = bufnr('')
endfunction

function! s:RunAsync() abort
  if !has('nvim-0.5')
    return
  endif
  call vista#SetProvider(s:provider)
  lua << EOF
    local params = vim.lsp.util.make_position_params()
    local callback = function(err, method_or_result, result_or_context)
        -- signature for the handler changed in neovim 0.6/master. The block
        -- below allows users to check the compatibility.
        local result
        if type(method_or_result) == 'string' then
          -- neovim 0.5.x
          result = result_or_context
        else
          -- neovim 0.6+
          result = method_or_result
        end

        if err then print(tostring(err)) return end
        if not result then return end
        data = vim.fn['vista#renderer#LSPPreprocess'](result)
        vim.fn['vista#executive#nvim_lsp#SetData'](data)
        vim.g.vista_executive_nvim_lsp_fetching = false
        if next(data) ~= nil then
          res = vim.fn['vista#renderer#LSPProcess'](data, vim.g.vista_executive_nvim_lsp_reload_only, vim.g.vista_executive_nvim_lsp_should_display)
          vim.g.vista_executive_nvim_lsp_reload_only = res[1]
          vim.g.vista_executive_nvim_lsp_should_display = res[2]
          vim.fn['vista#cursor#TryInitialRun']()
        end
    end
    vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, callback)
EOF
endfunction

function! vista#executive#nvim_lsp#Run(fpath) abort
  " TODO: check if the LSP service is registered for fpath.
  let s:fpath = a:fpath
  return s:Run()
endfunction

function! vista#executive#nvim_lsp#RunAsync() abort
  call s:RunAsync()
endfunction

function! vista#executive#nvim_lsp#Execute(bang, should_display, ...) abort
  call vista#source#Update(bufnr('%'), winnr(), expand('%'), expand('%:p'))
  let s:fpath = expand('%:p')

  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let g:vista.silent = v:false
  let g:vista_executive_nvim_lsp_should_display = a:should_display

  if a:bang
    return s:Run()
  else
    call s:RunAsync()
  endif
endfunction

function! vista#executive#nvim_lsp#Cache() abort
  return get(s:, 'cache', {})
endfunction
