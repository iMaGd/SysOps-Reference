#!/bin/bash

# Exit on error
set -e

# Updates the package list and installs required packages.
sudo apt update && sudo apt upgrade -y

# enables easier management of third-party software sources and is important when you want to install software from sources that are not available in the default Ubuntu repositories
sudo apt install -y software-properties-common

sudo apt install -y \
  unzip zip tar nano openssh-server \
  curl wget axel \
  htop pv tree git nano pwgen \
  openssl certbot

# Enable syntax highlighting globally for nano
echo "include /usr/share/nano/*.nanorc" >> ~/.nanorc


# Write Vim settings to ~/.vimrc
cat > ~/.vimrc <<'EOF'
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
set background=dark    " Use dark background (change to 'light' if needed)
colorscheme slate
EOF
