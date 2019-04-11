let s:default_icon = ['╰─▸ ', '├─▸ ']

function! vista#renderer#markdown#Render(data) abort
  " {'lnum': 1, 'level': '4', 'text': '# Vista.vim'}
  let data = a:data

  let rows = []

  for line in data
    let level = line.level
    let text = vista#util#Trim(line['text'][level : ])
    let lnum = line.lnum
    if level > 1
      let row = repeat(' ', 4 * level).s:default_icon[0].' '.text.' H'.level.':'.lnum
    else
      let row = text.':'.lnum
    endif

    let row = repeat(' ', 2 * level).s:default_icon[0].text.' H'.level.':'.lnum
    call add(rows, row)
  endfor

  return rows
endfunction
