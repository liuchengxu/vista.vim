---
name: Bug report
about: Create a report to help us improve
---

<!--
    Hello, thanks for reporting a bug.

    Please understand, that without clear explanations and useful info
    the issue may be closed as unreproducible.

    Thanks.
-->

**Describe the bug**
A clear and concise description of what the bug is.

**Environment:**
- OS: <!-- e.g. macOS, Ubuntu 18.04, Windows 10 -->
- Vim/Neovim version: <!-- first two lines of `:version` command output -->
- This plugin version: <!-- output of `git rev-parse origin/master` command -->
- I'm using universal-ctags: <!-- exuberant-ctags is unsupported -->
    - Ctags version: <!-- output of `ctags --version` command -->
- I'm using some LSP client:
    - Related Vim LSP client: <!-- ale,coc,lcn,nvim_lsp,vim_lsc,vim_lsp -->
    - The Vim LSP client version:
    - Have you tried updated to the latest version of this LSP client: Yes/No

**Vista info**

<!-- Paste the output of :Vista info here, or try :Vista info+. -->

```
```

**Steps to reproduce given the above info**
<!-- If this issue is related to ctags, please also provide the source file you run Vista on. -->

source file for reproduce the ctags issue:

<!-- If this issue is related to some LSP plugin, please also provide the minimal vimrc to help reproduce -->

minimal vimrc (neccessary when this issue is about some Vim LSP client):

```vim
set nocompatible
set runtimepath^=/path/to/vista.vim
syntax on
filetype plugin indent on
```

<!-- short descriptions of actions, which lead towards the issue -->
1.
2.
3.
4.

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
A clear and concise description of what actually happens.

**Screenshot or gif** (if possible)
If applicable, add screenshots to help explain your problem.
