" allow unsaved background buffers and remember marks/undo for them
set hidden

" remember more commands and search history
set history=10000

" 256 color terminal
let &t_Co=256

" Fix garbage characters appearing in xfce4-terminal
let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0

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

" Splits/window management
nnoremap <silent> <M-h> :<C-w>h
nnoremap <silent> <M-j> :<C-w>j
nnoremap <silent> <M-k> :<C-w>k
nnoremap <silent> <M-l> :<C-w>l

" yanking
nmap <silent> <M-y> "+y
vmap <silent> <M-y> "+y
map Y y$
