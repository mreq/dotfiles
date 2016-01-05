set nocompatible
filetype off

execute pathogen#infect('bundle/{}')

filetype plugin indent on

" 256 color terminal
let &t_Co=256

" Enable syntax highlight
syntax on

" Enable numbers
set number

" Font
set guifont=Ubuntu\ Mono\ 12

" Modify tab size
set tabstop=2

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
