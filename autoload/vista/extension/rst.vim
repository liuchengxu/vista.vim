" Copyright (c) 2019 Mathieu Clabaut
" MIT License
" vim: ts=2 sw=2 sts=2 et
"
" Heavily inspired  from https://raw.githubusercontent.com/Shougo/unite-outline/master/autoload/unite/sources/outline/defaults/rst.vim

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

function! s:GatherHeaderMetadata() abort
  let headers = []

  let s:lnum2tag = {}

  let idx = 0
  let adornment_levels = {}
  let adornment_id = 2

  let lines = g:vista.source.lines()
  while idx < len(lines)
    let line = lines[idx]
    let matched_line = get(lines, idx + 1, '')
    " Check the matching strictly.
    if matched_line =~# '^\([[:punct:]]\)\1\{3,}$' && line !~# '^\s*$'
      let text = vista#util#Trim(l:line)
      if idx > 1 && lines[idx - 1] == matched_line
        " Title
        let item = {'lnum': idx+1, 'text': text, 'level': 1}
      else
        " Sections
        let item = {'lnum': idx+1, 'text': text}
        let adchar = matched_line[0]
        if !has_key(l:adornment_levels, adchar)
          let l:adornment_levels[adchar] = l:adornment_id
          let l:adornment_id += 1
        endif
        let item['level'] = l:adornment_levels[adchar]
      endif
      let s:lnum2tag[len(headers)] = text
      call add(headers, l:item)
      let idx += 1
    endif
    let idx += 1
 endwhile

  return headers
endfunction

function! vista#extension#rst#GetHeader(lnum) abort
  return get(s:lnum2tag, a:lnum, v:null)
endfunction

function! s:ApplyAutoUpdate() abort
  if has_key(g:vista, 'bufnr') && g:vista.winnr() != -1
    call vista#SetProvider(s:provider)
    let rendered = vista#renderer#markdown_like#RST(s:GatherHeaderMetadata())
    call vista#util#SetBufline(g:vista.bufnr, rendered)
  endif
endfunction

function! vista#extension#rst#AutoUpdate(fpath) abort
  call s:AutoUpdate(a:fpath)
endfunction

function! s:AutoUpdate(fpath) abort
  if g:vista.source.filetype() ==# 'rst'
    call s:ApplyAutoUpdate()
  elseif g:vista.source.filetype() ==# 'markdown'
    call vista#extension#markdown#AutoUpdate(a:fpath)
  else
    call vista#executive#ctags#AutoUpdate(a:fpath)
  endif
endfunction

function! vista#extension#rst#Execute(_bang, should_display) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  if a:should_display
    let rendered = vista#renderer#markdown_like#RST(s:GatherHeaderMetadata())
    call vista#sidebar#OpenOrUpdate(rendered)
  endif
endfunction
