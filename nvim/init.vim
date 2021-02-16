" allow unsaved background buffers and remember marks/undo for them
set hidden

" remember more commands and search history
set history=10000

" 256 color terminal
let &t_Co=256
set termguicolors
set background=dark
colorscheme gruvbox

" Enable syntax highlight
syntax on

" Enable numbers
set number relativenumber

" Smart indenting
set autoindent

" Display incomplete command
set showcmd

" Always display the status line
set laststatus=2

" Disable swap file
set noswapfile

" Add fzf to runtime path
set rtp+=~/.fzf

" Load plugins
packloadall

" Splits/window management
nnoremap <silent> <M-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <M-j> :TmuxNavigateDown<cr>
nnoremap <silent> <M-k> :TmuxNavigateUp<cr>
nnoremap <silent> <M-l> :TmuxNavigateRight<cr>
nnoremap <silent> <M-x> <C-w>q

nnoremap <silent> <C-p> :FZF<cr>

" yanking
nmap <silent> <M-y> "+y
vmap <silent> <M-y> "+y
map Y y$
