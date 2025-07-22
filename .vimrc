" core vim settings
set nocompatible
filetype on
filetype plugin on
filetype indent on
syntax on
set number
set cursorline
set incsearch
inoremap jj <ESC> 
set guifont=Monaco:h18
set bg=dark

" bash completion
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" PLUGINS {{{

call plug#begin('~/.vim/plugged')

Plug 'morhetz/gruvbox'
Plug 'itchyny/lightline.vim'
Plug 'dense-analysis/ale'
Plug 'vimwiki/vimwiki'
Plug 'hashivim/vim-hashicorp-tools'
Plug 'hashivim/vim-terraform'

call plug#end()

" }}}


" VIMSCRIPT {{{

" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" More Vimscripts code goes here.

" }}}


" STATUS LINE {{{

" Clear status line when vimrc is reloaded.
set statusline=

" Status line left side.
set statusline+=\ %F\ %M\ %Y\ %R

" Use a divider to separate the left side from the right side.
set statusline+=%=

" Status line right side.
set statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%

" Show the status on the second to last line.
set laststatus=2

" }}}

colorscheme gruvbox
