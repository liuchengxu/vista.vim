" Copyright (c) 2019 Mathieu Clabaut
" MIT License
" vim: ts=2 sw=2 sts=2 et
"
" Heavily inspired  from https://raw.githubusercontent.com/Shougo/unite-outline/master/autoload/unite/sources/outline/defaults/rst.vim

let s:default_icon = get(g:, 'vista_icon_indent', ['╰─▸ ', '├─▸ '])

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

function! s:Execute() abort
  let headers = []

  let idx = 0
  let lines = t:vista.source.lines()
  let adornment_levels = {}
  let adornment_id = 2

  while idx < len(lines)
    let line = lines[idx]
    let matched_line = get(lines, idx + 1, '')
    " Check the matching strictly.
    if matched_line =~# '^\([[:punct:]]\)\1\{3,}$' && line !~# '^\s*$'
        if idx > 1 && lines[idx - 1] == matched_line
          " Title
          let item = {'lnum': idx, 'text': l:line, 'level': 1}
        else
          " Sections
          let item = {'lnum': idx, 'text': l:line}
          let adchar = matched_line[0]
          if !has_key(l:adornment_levels, adchar)
            let l:adornment_levels[adchar] = l:adornment_id
            let l:adornment_id += 1
          endif
          let l:adornment_levels[adchar] = l:adornment_id
          let l:adornment_id += 1
          endif
          let item['level'] = l:adornment_levels[adchar]
        endif
        call add(headers, l:item)
        let idx += 1
    endif
    let idx += 1
 endwhile

  return headers
endfunction

function! s:Render(data) abort
  " {'lnum': 1, 'level': '4', 'text': 'Vista.vim'}
  let data = a:data

  let rows = []

  for line in data
    let level = line.level
    let text = vista#util#Trim(line['text'])
    " line.lnum is 0-based, but the lnum of vim is 1-based.
    let lnum = line.lnum + 1

    let row = repeat(' ', 2 * level).s:default_icon[0].text.' H'.level.':'.lnum
    call add(rows, row)
  endfor

  return rows
endfunction

function! s:ApplyAutoUpdate() abort
  if has_key(t:vista, 'bufnr') && t:vista.winnr() != -1
    call vista#SetProvider(s:provider)
    let rendered = s:Render(s:Execute())
    call vista#util#SetBufline(t:vista.bufnr, rendered)
  endif
endfunction

function! vista#extension#rst#AutoUpdate(fpath) abort
  call s:AutoUpdate(a:fpath)
endfunction

function! s:AutoUpdate(fpath) abort
  if t:vista.source.filetype() ==# 'rst'
    call s:ApplyAutoUpdate()
  else
    call vista#executive#ctags#AutoUpdate(a:fpath)
  endif
endfunction

function! vista#extension#rst#Execute(_bang, should_display) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))

  let headers =  s:Execute()

  if a:should_display
    let rendered = s:Render(headers)
    call vista#sidebar#OpenOrUpdate(rendered)
  endif
endfunction
