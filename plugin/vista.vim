" vista.vim - View and search LSP symbols, tags, etc.
" Author:     Liu-Cheng Xu <xuliuchengxlc@gmail.com>
" Website:    https://github.com/liuchengxu/vista.vim
" License:    MIT

if exists('g:loaded_vista')
  finish
endif

let g:loaded_vista = 1

let g:vista_floating_border = get(g:, 'vista_floating_border', 'none')
let g:vista_sidebar_width = get(g:, 'vista_sidebar_width', 30)
let g:vista_sidebar_position = get(g:, 'vista_sidebar_position', 'vertical botright')
let g:vista_blink = get(g:, 'vista_blink', [2, 100])
let g:vista_top_level_blink = get(g:, 'vista_top_level_blink', [2, 100])
let g:vista_icon_indent = get(g:, 'vista_icon_indent', ['└ ', '│ '])
let g:vista_fold_toggle_icons = get(g:, 'vista_fold_toggle_icons', ['▼', '▶'])
let g:vista_update_on_text_changed = get(g:, 'vista_update_on_text_changed', 0)
let g:vista_update_on_text_changed_delay = get(g:, 'vista_update_on_text_changed_delay', 500)
let g:vista_echo_cursor = get(g:, 'vista_echo_cursor', 1)
let g:vista_no_mappings = get(g:, 'vista_no_mappings', 0)
let g:vista_stay_on_open = get(g:, 'vista_stay_on_open', 1)
let g:vista_close_on_jump =  get(g:, 'vista_close_on_jump', 0)
let g:vista_close_on_fzf_select =  get(g:, 'vista_close_on_fzf_select', 0)
let g:vista_disable_statusline = get(g:, 'vista_disable_statusline', exists('g:loaded_airline') || exists('g:loaded_lightline'))
let g:vista_cursor_delay = get(g:, 'vista_cursor_delay', 400)
let g:vista_ignore_kinds = get(g:, 'vista_ignore_kinds', [])
let g:vista_executive_for = get(g:, 'vista_executive_for', {})
let g:vista_default_executive = get(g:, 'vista_default_executive', 'ctags')
let g:vista_enable_centering_jump = get(g:, 'vista_enable_centering_jump', 1)
let g:vista_find_nearest_method_or_function_delay = get(g:, 'vista_find_nearest_method_or_function_delay', 300)
" Select the absolute nearest function when using binary search.
let g:vista_find_absolute_nearest_method_or_function = get(g:, 'vista_find_absolute_nearest_method_or_function', 0)
let g:vista_fzf_preview = get(g:, 'vista_fzf_preview', [])

command! -bang -nargs=* -bar -complete=custom,vista#util#Complete Vista call vista#(<bang>0, <f-args>)
