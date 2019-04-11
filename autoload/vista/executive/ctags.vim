" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:ctags = get(g:, 'vista_ctags_executable', 'ctags')
let s:support_json_format =
      \ len(filter(split(system(s:ctags.' --list-features'), '\n'), 'v:val =~# ''^json''')) > 0

function! s:GetCustomCmd(ft) abort
  if exists('g:vista_ctags_cmd') && has_key(g:vista_ctags_cmd, a:ft)
    return g:vista_ctags_cmd[a:ft]
  endif
  return v:null
endfunction

function! s:GetLanguageSpecificOptition(filetype) abort
  let opt = ''

  try

    let types = g:vista#types#uctags#{a:filetype}#
    let lang = types.lang
    let kinds = join(keys(types.kinds), '')
    let opt = printf('--language-force=%s --%s-kinds=%s', lang, lang, kinds)

  " Ignore Vim(let):E121: Undefined variable
  catch /^Vim\%((\a\+)\)\=:E121/
  endtry

  return opt
endfunction

" FIXME support all languages that ctags does
function! s:BuildCmd(file) abort
  let ft = &filetype

  " Refer to tagbar
  let common_opt = '--format=2 --excmd=pattern --fields=nksSaf --extras= --file-scope=yes --sort=no --append=no'
  let language_specific_opt = s:GetLanguageSpecificOptition(ft)

  " TODO vista_ctags_{filetype}_executable
  if s:support_json_format
    let fmt = '%s %s %s --output-format=json -f- %s'
    let s:TagParser = function('vista#parser#ctags#FromJSON')
  else
    let fmt = '%s %s %s -f- %s'
    let s:TagParser = function('vista#parser#ctags#FromExtendedRaw')
  endif

  let cmd = printf(fmt, s:ctags, common_opt, language_specific_opt, a:file)

  let custom_cmd = s:GetCustomCmd(ft)

  if custom_cmd isnot v:null
    if stridx(custom_cmd, '--output-format=json') > -1
      let s:TagParser = function('vista#parser#ctags#FromJSON')
    else
      let s:TagParser = function('vista#parser#ctags#FromExtendedRaw')
    endif
    let cmd = printf('%s %s', custom_cmd, a:file)
  endif

  return cmd
endfunction

function! s:PrepareContainer() abort
  let s:data = {}
  let t:vista.functions = []
  let t:vista.raw = []
  let t:vista.kinds = []
endfunction

function! s:on_exit(_job, _data, _event) abort dict
  if v:dying | return | endif

  " Second last line is the real last one in neovim
  call s:ExtractLinewise(self.stdout[:-2])

  call s:ApplyExtracted()

  if exists('s:id')
    unlet s:id
  endif
endfunction

function! s:close_cb(channel) abort
  call s:PrepareContainer()

  while ch_status(a:channel, {'part': 'out'}) ==# 'buffered'
    let line = ch_read(a:channel)
    call call(s:TagParser, [line, s:data])
  endwhile

  call s:ApplyExtracted()

  if exists('s:id')
    unlet s:id
  endif
endfunction

function! s:ApplyExtracted() abort
  " Update cache when new data comes.
  let s:cache = get(s:, 'cache', {})
  let s:cache[s:fpath] = s:data
  let s:cache.ftime = getftime(s:fpath)
  let s:cache.bufnr = bufnr('')

  if s:reload_only
    call vista#sidebar#Reload(s:data)
    let s:reload_only = v:false
    return
  endif

  if s:should_display
    call vista#viewer#Display(s:data)
    let s:should_display = v:false
  endif
endfunction

function! s:ExtractLinewise(raw_data) abort
  call s:PrepareContainer()
  call map(a:raw_data, 'call(s:TagParser, [v:val, s:data])')
endfunction

function! s:AutoUpdate(fpath) abort
  if t:vista.source.filetype() ==# 'markdown'
    call vista#extension#markdown#AutoUpdate(a:fpath)
  else
    let s:reload_only = v:true
    call s:ApplyExecute(v:false, a:fpath)
  endif
endfunction

function! vista#executive#ctags#AutoUpdate(fpath) abort
  call s:AutoUpdate(a:fpath)
endfunction

" Run ctags synchronously given the cmd
function! s:ApplyRun(cmd) abort
  let output = system(a:cmd)
  if v:shell_error
    return vista#error#('Fail to run ctags: '.a:cmd)
  endif

  let s:cache = get(s:, 'cache', {})
  let s:cache.fpath = s:fpath

  call s:ExtractLinewise(split(output, "\n"))
endfunction

" Run ctags asynchronously given the cmd
function! s:ApplyRunAsync(cmd) abort
  if has('nvim')
    " job is job id in neovim
    let jobid = jobstart(a:cmd, {
            \ 'stdout_buffered': 1,
            \ 'stderr_buffered': 1,
            \ 'on_exit': function('s:on_exit')
            \ })
  else
    let job = job_start(a:cmd, {
          \ 'close_cb':function('s:close_cb')
          \ })
    let jobid = matchstr(job, '\d\+') + 0
  endif

  return jobid > 0 ? jobid : 0
endfunction

" Use a temporary files for ctags processing instead of the original one.
" This allows using Tagbar for files accessed with netrw, and also doesn't
" slow down Tagbar for files that sit on slow network drives.
" This idea comes from tagbar.
function! s:IntoTemp(...) abort
  let tmp = tempname()
  let ext = t:vista.source.extension()
  if !empty(ext)
    let tmp = join([tmp, ext], '.')
  endif

  if empty(a:1)
    let lines = t:vista.source.lines()
  else
    try
      let lines = readfile(a:1)
    " Vim cannot read a temporary file, this may happen when you open vim with
    " a file which does not exist yet, e.g., 'vim does_exist_yet.txt'
    catch /E484/
      return
    endtry
  endif

  if writefile(lines, tmp) == 0
    return tmp
  else
    return vista#error#('Fail to write into a temp file.')
  endif
endfunction

function! s:ApplyExecute(bang, fpath) abort
  let file = s:IntoTemp(a:fpath)
  if empty(file)
    return
  endif

  let cmd = s:BuildCmd(file)

  if a:bang
    call s:ApplyRun(cmd)
  else
    if exists('s:id')
      call vista#util#JobStop(s:id)
    endif

    let s:id = s:ApplyRunAsync(cmd)

    if s:id == 0
      call vista#error#RunCtags(cmd)
    endif
  endif
endfunction

function! s:Run(fpath) abort
  let file = s:IntoTemp(a:fpath)
  if empty(file)
    return
  endif

  let s:fpath = a:fpath

  let cmd = s:BuildCmd(file)
  call s:ApplyRun(cmd)

  return s:data
endfunction

function! s:RunAsync(fpath) abort
  let file = s:IntoTemp(a:fpath)
  if empty(file)
    return
  endif

  let cmd = s:BuildCmd(file)

  if exists('s:id')
    call vista#util#JobStop(s:id)
  endif

  let s:id = s:ApplyRunAsync(cmd)

  if !s:id
    call vista#error#RunCtags(cmd)
  endif
endfunction

function! s:Execute(bang, should_display) abort
  let s:should_display = a:should_display
  let s:fpath = expand('%:p')
  call s:ApplyExecute(a:bang, s:fpath)
endfunction

function! s:Dispatch(F, ...) abort
  let ft = &filetype
  let custom_cmd = s:GetCustomCmd(ft)

  let exe = custom_cmd isnot v:null ? split(custom_cmd)[0] : 'ctags'

  if !executable(exe)
    call vista#error#Need(exe)
    return
  endif

  return call(function(a:F), a:000)
endfunction

function! vista#executive#ctags#Cache() abort
  return get(s:, 'cache', {})
endfunction

" Run ctags given the cmd synchronously
function! vista#executive#ctags#Run(fpath) abort
  return s:Dispatch('s:Run', a:fpath)
endfunction

" Run ctags given the cmd asynchronously
function! vista#executive#ctags#RunAsync(fpath) abort
  call s:Dispatch('s:RunAsync', a:fpath)
endfunction

function! vista#executive#ctags#Execute(bang, should_display, ...) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))
  return s:Dispatch('s:Execute', a:bang, a:should_display)
endfunction

" Run ctags recursively.
function! vista#executive#ctags#ProjectRun() abort
  " https://github.com/universal-ctags/ctags/issues/2042
  "
  " If ctags has the json format feature, we should use the
  " `--output-format=json` option, which is easier to parse and more reliable.
  " Otherwise we will use the `--_xformat` option.
  if s:support_json_format
    let cmd = s:ctags.' -R -x --output-format=json --fields=+n'
    let Parser = function('vista#parser#ctags#RecursiveFromJSON')
  else
    let cmd = s:ctags." -R -x --_xformat='TAGNAME:%N ++++ KIND:%K ++++ LINE:%n ++++ INPUT-FILE:%F ++++ PATTERN:%P'"
    let Parser = function('vista#parser#ctags#RecursiveFromXformat')
  endif

  let output = system(cmd)
  if v:shell_error
    return vista#error#RunCtags(cmd)
  endif

  let s:data = {}

  call map(split(output, "\n"), 'call(Parser, [v:val, s:data])')

  return s:data
endfunction
