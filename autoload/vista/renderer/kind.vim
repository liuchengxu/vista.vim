" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et
"
" Render the content by the kind of tag.
scriptencoding utf8

let s:viewer = {}

function! s:viewer.init(data) abort
  let self.rows = []
  let self.data = a:data

  let self.prefixes = g:vista_icon_indent

  " TODO improve me!
  let up_gap = strwidth(self.prefixes[0])
  " By default the gap is half of the second prefix.
  " at least one
  if up_gap >= 2 && up_gap < 4
    let self.gap = up_gap
  elseif up_gap >= 4
    let self.gap = up_gap / 2
  else
    let self.gap = up_gap + strwidth(self.prefixes[1])/2
  endif
endfunction

function! s:ContainWhitespaceOnly(str) abort
  return a:str !~# '\S'
endfunction

function! s:Compare(i1, i2) abort
  return a:i1.text > a:i2.text
endfunction

function! s:viewer.render() abort
  let try_adjust = self.prefixes[0] != self.prefixes[1]

  " prefixes[0] scope [children_num]
  "   prefixes[1] tag:num
  for [kind, v] in items(self.data)
    let parent = self.prefixes[0] .vista#renderer#Decorate(kind).' ['.len(v).']'
    " Parent
    call add(self.rows, parent)

    if !empty(v) && type(v) == type([])

      if get(g:vista, 'sort', v:false)
        let v = sort(copy(v), function('s:Compare'))
      endif

      " Children
      for i in v
        if len(i) > 0
          let row = vista#util#Join(
                \ repeat(' ', self.gap),
                \ self.prefixes[1],
                \ i.text,
                \ ':'.i.lnum
                \ )
          call add(self.rows, row)
        endif
      endfor

      if !s:ContainWhitespaceOnly(self.prefixes[1]) && try_adjust
        " Adjust the prefix of last item in each scope
        let tag_colon_num = split(self.rows[-1], ' ')[1:]
        let self.rows[-1] = repeat(' ', self.gap)
              \ .self.prefixes[0]
              \ .join(tag_colon_num, ' ')
      endif
    endif

    call add(self.rows, '')
  endfor

  " Remove the needless last empty line
  unlet self.rows[-1]

  return self.rows
endfunction

function! vista#renderer#kind#Render(data) abort
  if empty(a:data)
    return []
  endif
  call s:viewer.init(a:data)
  return s:viewer.render()
endfunction
