" vista.vim - View and search LSP symbols, tags, etc.
" Author:     Liu-Cheng Xu <xuliuchengxlc@gmail.com>
" Website:    https://github.com/liuchengxu
" License:    MIT

command! -bang -nargs=* -bar -complete=custom,vista#util#Complete Vista call vista#(<bang>0, <f-args>)
