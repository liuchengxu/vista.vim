" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

function! s:IsHeader(cur_line, next_line) abort
  return a:cur_line =~# '^#\+' ||
        \ a:cur_line =~# '^\S' && (a:next_line =~# '^=\+\s*$' || a:next_line =~# '^-\+\s*$')
endfunction

function! s:Execute() abort
  let is_fenced_block = 0

  let headers = []

  let idx = 0
  let lines = t:vista.source.lines()

  for line in lines
    let line = substitute(line, '#', "\\\#", 'g')
    let next_line = get(lines, idx + 1, '')

    if l:line =~# '````*' || l:line =~# '\~\~\~\~*'
      let is_fenced_block = !is_fenced_block
    endif

    let is_header = s:IsHeader(l:line, l:next_line)

    if is_header && !is_fenced_block
        let item = {'lnum': idx+1, 'text': l:line}
        let matched = matchlist(l:line, '\#*')
        let item['level'] = len(matched[0])
        call add(headers, l:item)
    endif

    let idx += 1
  endfor

  return headers
endfunction

function! s:ApplyAutoUpdate() abort
  if has_key(t:vista, 'bufnr') && t:vista.winnr() != -1
    call vista#SetProvider(s:provider)
    let rendered = vista#renderer#markdown_like#MD(s:Execute())
    call vista#util#SetBufline(t:vista.bufnr, rendered)
  endif
endfunction

function! vista#extension#markdown#AutoUpdate(fpath) abort
  call s:AutoUpdate(a:fpath)
endfunction

function! s:AutoUpdate(fpath) abort
  if t:vista.source.filetype() ==# 'markdown'
    call s:ApplyAutoUpdate()
  elseif t:vista.source.filetype() ==# 'rst'
    call vista#extension#rst#AutoUpdate(a:fpath)
  else
    call vista#executive#ctags#AutoUpdate(a:fpath)
  endif
endfunction

" Credit: originally from `:Toc` of vim-markdown
function! vista#extension#markdown#Execute(_bang, should_display) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  if a:should_display
    let headers = s:Execute()
    let rendered = vista#renderer#markdown_like#MD(headers)
    call vista#sidebar#OpenOrUpdate(rendered)
  endif
endfunction
