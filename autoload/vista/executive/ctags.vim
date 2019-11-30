" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

let s:provider = fnamemodify(expand('<sfile>'), ':t:r')

let s:reload_only = v:false
let s:should_display = v:false

let s:ctags = get(g:, 'vista_ctags_executable', 'ctags')
let s:support_json_format =
      \ len(filter(split(system(s:ctags.' --list-features'), '\n'), 'v:val =~# ''^json''')) > 0

let s:is_mac = has('macunix')
let s:is_linux = has('unix') && !has('macunix') && !has('win32unix')

let s:can_async = has('patch-8.0.0027')

" Expose this variable for debugging
let g:vista#executive#ctags#support_json_format = s:support_json_format

function! s:GetCustomCmd(ft) abort
  if exists('g:vista_ctags_cmd') && has_key(g:vista_ctags_cmd, a:ft)
    return g:vista_ctags_cmd[a:ft]
  endif
  return v:null
endfunction

function! s:GetDefaultCmd(file) abort
  " Refer to tagbar
  let common_opt = '--format=2 --excmd=pattern --fields=nksSaf --file-scope=yes --sort=no --append=no'

  " Do not pass --extras for C/CPP in order to let uctags handle the tags for anonymous
  " entities correctly.
  if t:vista.source.filetype() !=# 'c' && t:vista.source.filetype() !=# 'cpp'
    let common_opt .= ' --extras= '
  endif

  if s:support_json_format
    let fmt = '%s %s %s --output-format=json --fields=-PF -f- %s'
    let s:TagParser = function('vista#parser#ctags#FromJSON')
  else
    let fmt = '%s %s %s -f- %s'
    let s:TagParser = function('vista#parser#ctags#FromExtendedRaw')
  endif

  let language_specific_opt = s:GetLanguageSpecificOptition(&filetype)
  let cmd = printf(fmt, s:ctags, common_opt, language_specific_opt, a:file)

  return cmd
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
  let custom_cmd = s:GetCustomCmd(&filetype)

  if custom_cmd isnot v:null
    if stridx(custom_cmd, '--output-format=json') > -1
      let s:TagParser = function('vista#parser#ctags#FromJSON')
    else
      let s:TagParser = function('vista#parser#ctags#FromExtendedRaw')
    endif
    let cmd = printf('%s %s', custom_cmd, a:file)
  else
    let cmd = s:GetDefaultCmd(a:file)
  endif

  let t:vista.ctags_cmd = cmd

  return cmd
endfunction

function! s:PrepareContainer() abort
  let s:data = {}
  let t:vista = get(t:, 'vista', {})
  let t:vista.functions = []
  let t:vista.raw = []
  let t:vista.kinds = []
  let t:vista.raw_by_kind = {}
  let t:vista.with_scope = []
  let t:vista.without_scope = []
endfunction

function! s:on_exit(_job, _data, _event) abort dict
  if !exists('t:vista') || v:dying
    return
  endif

  " Second last line is the real last one in neovim
  call s:ExtractLinewise(self.stdout[:-2])

  call s:ApplyExtracted()
endfunction

function! s:close_cb(channel) abort
  call s:PrepareContainer()

  while ch_status(a:channel, {'part': 'out'}) ==# 'buffered'
    let line = ch_read(a:channel)
    call s:TagParser(line, s:data)
  endwhile

  call s:ApplyExtracted()
endfunction

" Process the preprocessed output by ctags and remove s:id.
function! s:ApplyExtracted() abort
  " Update cache when new data comes.
  let s:cache = get(s:, 'cache', {})
  let s:cache[s:fpath] = s:data
  let s:cache.ftime = getftime(s:fpath)
  let s:cache.bufnr = bufnr('')

  let [s:reload_only, s:should_display] = vista#renderer#LSPProcess(s:data, s:reload_only, s:should_display)

  if exists('s:id')
    unlet s:id
  endif
endfunction

function! s:ExtractLinewise(raw_data) abort
  call s:PrepareContainer()
  call map(a:raw_data, 'call(s:TagParser, [v:val, s:data])')
endfunction

function! s:AutoUpdate(fpath) abort
  if t:vista.source.filetype() ==# 'markdown'
        \ && get(g:, 'vista_enable'.&filetype.'_extension', 1)
    call vista#extension#{&ft}#AutoUpdate(a:fpath)
  else
    call vista#OnExecute(s:provider, function('s:AutoUpdate'))
    let s:reload_only = v:true
    call s:ApplyExecute(v:false, a:fpath)
  endif
endfunction

function! vista#executive#ctags#AutoUpdate(fpath) abort
  call vista#OnExecute(s:provider, function('s:AutoUpdate'))
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

if has('nvim')
  " Run ctags asynchronously given the cmd
  function! s:ApplyRunAsync(cmd) abort
      " job is job id in neovim
      let jobid = jobstart(a:cmd, {
              \ 'stdout_buffered': 1,
              \ 'stderr_buffered': 1,
              \ 'on_exit': function('s:on_exit')
              \ })
    return jobid > 0 ? jobid : 0
  endfunction
else

  if has('win32')
    function! s:WrapCmd(cmd) abort
      return &shell . ' ' . &shellcmdflag . ' ' . a:cmd
    endfunction
  else
    function! s:WrapCmd(cmd) abort
      return split(&shell) + split(&shellcmdflag) + [a:cmd]
    endfunction
  endif

  function! s:ApplyRunAsync(cmd) abort
    let job = job_start(s:WrapCmd(a:cmd), {
          \ 'close_cb':function('s:close_cb')
          \ })
    let jobid = matchstr(job, '\d\+') + 0
    return jobid > 0 ? jobid : 0
  endfunction
endif

function! s:TryAppendExtension(tempname) abort
  let ext = t:vista.source.extension()
  if !empty(ext)
    return join([a:tempname, ext], '.')
  else
    return a:tempname
  endif
endfunction

function! s:BuiltinTempname() abort
  let tempname = tempname()
  return s:TryAppendExtension(tempname)
endfunction

function! s:TempnameBasedOnSourceBufname() abort
  let tempname = sha256(fnamemodify(bufname(t:vista.source.bufnr), ':p'))
  return s:TryAppendExtension(tempname)
endfunction

function! s:Tempdir() abort
  let tmpdir = $TMPDIR
  if empty(tmpdir)
    let tmpdir = '/tmp/'
  elseif tmpdir !~# '/$'
    let tmpdir .= '/'
  endif
  return tmpdir
endfunction

" Use a temporary files for ctags processing instead of the original one.
" This allows using Tagbar for files accessed with netrw, and also doesn't
" slow down Tagbar for files that sit on slow network drives.
" This idea comes from tagbar.
function! s:IntoTemp(...) abort
  " Don't use tempname() if possible since it would cause the changing of the anonymous tag name.
  "
  " Ref: https://github.com/liuchengxu/vista.vim/issues/122#issuecomment-511115932
  try
    if exists('$TMPDIR')
      let tmpdir = s:Tempdir()
      let tempname = s:TempnameBasedOnSourceBufname()
      let tmp = tmpdir.tempname
    else
      if s:is_mac || s:is_linux
        let tmpdir = '/tmp/vista.vim_ctags_tmp/'
        if !isdirectory(tmpdir)
          call mkdir(tmpdir)
        endif
        let tempname = s:TempnameBasedOnSourceBufname()
        let tmp = tmpdir.tempname
      endif
    endif
  catch
  endtry

  if !exists('l:tmp')
    let tmp = s:BuiltinTempname()
  endif

  if get(t:vista, 'on_text_changed', 0)
    let lines = t:vista.source.lines()
    let t:vista.on_text_changed = 0
  else
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

  let s:fpath = a:fpath

  let cmd = s:BuildCmd(file)

  if a:bang || !s:can_async
    call s:ApplyRun(cmd)
  else
    call s:RunAsyncCommon(cmd)
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

function! s:RunAsyncCommon(cmd) abort
  if exists('s:id')
    call vista#util#JobStop(s:id)
  endif

  let s:id = s:ApplyRunAsync(a:cmd)

  if !s:id
    call vista#error#RunCtags(a:cmd)
  endif
endfunction

function! s:RunAsync(fpath) abort
  if s:can_async
    let file = s:IntoTemp(a:fpath)
    if empty(file)
      return
    endif

    let cmd = s:BuildCmd(file)
    call s:RunAsyncCommon(cmd)
  endif
endfunction

function! s:Execute(bang, should_display) abort
  let s:should_display = a:should_display
  let s:fpath = expand('%:p')
  call s:ApplyExecute(a:bang, s:fpath)
endfunction

function! s:Dispatch(F, ...) abort
  let custom_cmd = s:GetCustomCmd(&filetype)

  let exe = custom_cmd isnot v:null ? split(custom_cmd)[0] : 'ctags'

  if !executable(exe)
    call vista#error#Need(exe)
    return
  endif

  call vista#SetProvider(s:provider)
  return call(function(a:F), a:000)
endfunction

function! vista#executive#ctags#Cache() abort
  return get(s:, 'data', {})
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
