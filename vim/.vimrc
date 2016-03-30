set nocompatible
filetype off

execute pathogen#infect('bundle/{}')

filetype plugin indent on

" 256 color terminal
let &t_Co=256

" Change leader key
let mapleader=" "

" Enable syntax highlight
syntax on

" Enable numbers
set number
set relativenumber

" Font
if has("gui_running")
  if has("gui_gtk2")
    set guifont=Ubuntu\ Mono\ 12
  elseif has("gui_win32")
    set guifont=Consolas:h12
  endif
endif

" Modify tab size
set tabstop=2

" Convert tabs to spaces
set expandtab

" Smart indenting
set autoindent

" Auto-trim trailing whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Set color scheme
set background=dark
colorscheme gruvbox

" Enable file system for tab completions
filetype plugin on
filetype indent on

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Keybinds
nnoremap ; :
map <Leader>k <C-W>k
map <Leader>j <C-W>j
map <Leader>h <C-W>h
map <Leader>l <C-W>l
map <Leader>t gt
map <Leader>T gT
