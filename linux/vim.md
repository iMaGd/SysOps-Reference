### Insert Mode

```bash
i                   insert before cursor
I                   insert at the beginning of the line
a                   insert after cursor
A                   insert at the end of the line
o                   open a new line below the cursor
O                   open a new line above the cursor

# deleting text
x                   delete current character
X                   delete previous character
dd                  delete (cut) a line
dw                  delete (cut) to the end of word (same as de)
diw                 delete (cut) word under the cursor
daw                 delete (cut) word under the cursor and the space after or before it
dap                 delete (cut) a paragraph
```

### Normal Mode (Exiting Vim)

```bash
:q                  quit Vim. This fails when changes have been made.
:q!                 quit without writing.
:cq                 quit always, without writing.
:w                  save without exiting.
:wq                 write the current file and exit.
:wq!                write the current file and exit always.
:wq {file}          write to {file}. Exit if not editing the last
:wq! {file}         write to {file} and exit always.
:[range]wq[!]       same as above, but only write the lines in [range].
ZZ                  write current file, if modified, and exit.
ZQ                  quit current file and exit (same as ":q!").
```

### Visual Mode

```bash
v                   enter visual mode
V                   enter visual line mode
```

----

### Vim Config file `~/.vimrc`

```bash
" Basic Settings
set nocompatible        " Use Vim defaults (not vi)
set number              " Show line numbers
set tabstop=4           " Number of spaces a tab counts for
set shiftwidth=4        " Number of spaces to use for auto-indent
set expandtab           " Use spaces instead of tabs
set autoindent          " Copy indent from previous line
set smartindent         " Smart auto-indenting for programs
set wrap                " Wrap long lines
set encoding=utf-8      " Use UTF-8 encoding
set fileencodings=utf-8 " Use UTF-8 for file encoding

" Syntax and Colors
syntax on              " Enable syntax highlighting
set background=dark    " Use dark or light
colorscheme
```
