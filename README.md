# Vista.vim
[![Build Status](https://travis-ci.org/liuchengxu/vista.vim.svg?branch=master)](https://travis-ci.org/liuchengxu/vista.vim)

View and search LSP symbols, tags in Vim/NeoVim.

<p align="center">
    <img width="600px" src="https://user-images.githubusercontent.com/8850248/54874346-88a7d380-4e24-11e9-8574-fb4c56085e9d.gif">
</p>

:warning: **Currently vista.vim is mostly usable, yet not stable. All the public APIs and global options can be changed or even be removed in the future.**

## Table Of Contents
<!-- TOC GFM -->

* [Introduction](#introduction)
* [Features](#features)
* [Requirement](#requirement)
* [Installation](#installation)
    * [Plugin Manager](#plugin-manager)
    * [Package management](#package-management)
        * [Vim 8](#vim-8)
        * [NeoVim](#neovim)
* [Usage](#usage)
    * [Show the nearest method/function in the statusline](#show-the-nearest-methodfunction-in-the-statusline)
        * [lightline.vim](#lightlinevim)
    * [Commands](#commands)
    * [Options](#options)
    * [Other tips](#other-tips)
        * [Compile ctags with JSON format support](#compile-ctags-with-json-format-support)
* [Contributing](#contributing)
* [License](#license)

<!-- /TOC -->

## Introduction

I initially started [vista.vim](https://github.com/liuchengxu/vista.vim) with an intention of replacing [tagbar](https://github.com/majutsushi/tagbar) as it seemingly doesn't have a plan to support the promising [Language Server Protocol](https://github.com/Microsoft/language-server-protocol) and async processing.

In terms of viewer for ctags-generated tags, [vista.vim](https://github.com/liuchengxu/vista.vim) is sort of the poor version of tagbar, for some details has not been worked out. Nonetheless, it's more than a tags viewer.

Vista.vim can also be a symbol navigator similar to [ctrlp-funky](https://github.com/tacahiroy/ctrlp-funky). Last but not least, one important goal of [vista.vim](https://github.com/liuchengxu/vista.vim) is to support LSP symbols, which understands the semantics instead of the regex only.

<p align="center">
    <img width="600px" src="https://raw.githubusercontent.com/liuchengxu/img/master/vista.vim/vista.png">
</p>

## Features

- [x] View tags and LSP symbols in a sidebar.
    - [x] [universal-ctags](https://github.com/universal-ctags/ctags)
    - [x] [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
    - [x] [coc.nvim](https://github.com/neoclide/coc.nvim)
    - [x] [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
- [x] Finder for tags and LSP symbols.
    - [x] [fzf](https://github.com/junegunn/fzf)
- [x] Display decent detailed symbol info in cmdline, also supports neovim's floating window.
- [x] Jump to the tag/symbol from vista sidebar with a blink.
- [x] Update automatically when switching between buffers.
- [x] Update asynchonously in the background when `+job` avaliable.
- [x] Find the nearest method or function to the cursor, which could be integrated into the statusline.
- [ ] Highlight the nearest tag/symbol in the vista sidebar.
- [ ] Supports all of the languages that ctags does.
- [ ] Show the visibility (public/private) of tags.
- [ ] Tree viewer for hierarchy data.

Notes:

- The feature of finder in vista.vim `:Vista finder [EXECUTIVE]` is a bit like `:BTags` or `:Tags` in [fzf.vim](https://github.com/junegunn/fzf.vim), `:CocList` in [coc.nvim](https://github.com/neoclide/coc.nvim), `:LeaderfBufTag` in [leaderf.vim](https://github.com/Yggdroot/LeaderF), etc. You can choose whatever you like.

- I personally don't use all the features I have listed. Hence some of them may be on the TODOs forever :(.

## Requirement

I don't know the mimimal supported version. But if you only care about the ctags related feature, vim 7.4.1154+ should be enough.

Otherwise, if you want to try any LSP related features, then you certainly need some plugins to retrive the LSP symbols, e.g., [coc.nvim](https://github.com/neoclide/coc.nvim). When you have these LSP plugins set up, vista.vim should be ok to go as well.

In addition, if you want to search the symbols via [fzf](https://github.com/junegunn/fzf), you will have to install it first.

## Installation

### Plugin Manager

- [vim-plug](https://github.com/junegunn/vim-plug)

    ```vim
    Plug 'liuchengxu/vista.vim'
    ```

For other plugin managers please follow their instructions accordingly.

### Package management

#### Vim 8

```bash
$ mkdir -p ~/.vim/pack/git-plugins/start
$ git clone https://github.com/liuchengxu/vista.vim.git --depth=1 ~/.vim/pack/git-plugins/start/vista.vim
```

#### NeoVim

```bash
$ mkdir -p ~/.local/share/nvim/site/pack/git-plugins/start
$ git clone https://github.com/liuchengxu/vista.vim.git --depth=1 ~/.local/share/nvim/site/pack/git-plugins/start/vista.vim
```

## Usage

### Show the nearest method/function in the statusline

You can do the following to show the nearest method/function in your statusline:

```vim
function! NearestMethodOrFunction() abort
  return get(b:, 'vista_nearest_method_or_function', '')
endfunction

set statusline+=%{NearestMethodOrFunction()}

" By default vista.vim never run if you don't call it explicitly.
"
" If you want to show the nearest function in your statusline automatically,
" you can add the following line to your vimrc 
autocmd VimEnter * call vista#RunForNearestMethodOrFunction()
```

Also refer to [liuchengxu/eleline#18](https://github.com/liuchengxu/eleline.vim/pull/18).

<p align="center">
    <img width="800px" src="https://user-images.githubusercontent.com/8850248/55477900-da363680-564c-11e9-8e71-845260f3d44b.png">
</p>

#### [lightline.vim](https://github.com/itchyny/lightline.vim)

```vim
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified', 'method' ] ]
      \ },
      \ 'component_function': {
      \   'method': 'NearestMethodOrFunction'
      \ },
      \ }
```

### Commands

Command   | Description
:----     | :----
`Vista`   | Open vista window for viewing tags or LSP symbols
`Vista!`  | Close vista view window if already opened
`Vista!!` | Toggle vista view window

`:Vista [EXECUTIVE]`: open vista window powered by EXECUTIVE.

`:Vista finder [EXECUTIVE]`: search tags/symbols generated from EXECUTIVE.

See `:help vista-commands` for more information.

### Options

```vim
" How each level is indented and what to prepend.
" This could make the display more compact or more spacious.
" e.g., more compact: ["▸ ", ""]
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]

" Executive used when opening vista sidebar without specifying it.
" See all the avaliable executives via `:echo g:vista#executives`.
let g:vista_default_executive = 'ctags'

" Set the executive for some filetypes explicitly. Use the explicit executive
" instead of the default one for these filetypes when using `:Vista` without
" specifying the executive.
let g:vista_executive_for = {
  \ 'cpp': 'vim_lsp',
  \ 'php': 'vim_lsp',
  \ }

" Declare the command including the executable and options used to generate ctags output
" for some certain filetypes.The file path will be appened to your custom command.
" For example:
let g:vista_ctags_cmd = {
      \ 'haskell': 'hasktags -x -o - -c',
      \ }

" To enable fzf's preview window set g:vista_fzf_preview.
" The elements of g:vista_fzf_preview will be passed as arguments to fzf#vim#with_preview()
" For example:
let g:vista_fzf_preview = ['right:50%']
```

```vim
" Ensure you have installed some decent font to show these pretty symbols, then you can enable icon for the kind.
let g:vista#renderer#enable_icon = 1

" The default icons can't be suitable for all the filetypes, you can extend it as you wish.
let g:vista#renderer#icons = {
\   "function": "\uf794",
\   "variable": "\uf71b",
\  }
```

<p align="center">
    <img width="300px" src="https://user-images.githubusercontent.com/8850248/55805524-2b449f80-5b11-11e9-85d4-018c305a5ecb.png">
</p>

See `:help vista-options` for more information.

### Other tips

#### Compile ctags with JSON format support

First of all, check if your ctags supports JSON format via `ctags --list-features`. If not, I recommend you to install ctags with JSON format support that would make vista's parser easier and more reliable. [universal-ctags](https://github.com/universal-ctags/ctags) has JSON output mode, it's avaliable if u-ctags is linked to libjansson.

- macOS

    ```bash
    brew install --with-jansson universal-ctags/universal-ctags/universal-ctags
    ```

- Ubuntu

    ```bash
    # install libjansson first
    sudo apt-get install libjansson-dev

    # then compile and install ctags
    ```

    Refer to [Compiling and Installing Jansson](https://jansson.readthedocs.io/en/latest/gettingstarted.html#compiling-and-installing-jansson) as well.


## Contributing

Vista.vim is still in beta, please [file an issue](https://github.com/liuchengxu/vista.vim/issues/new) if you run into any trouble or have any sugguestions.

## License

MIT

Copyright (c) 2019 Liu-Cheng Xu
