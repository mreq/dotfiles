call plug#begin()
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'ap/vim-buftabline'
Plug 'chriskempson/base16-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'miyakogi/conoline.vim'
Plug 'slim-template/vim-slim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-surround'
Plug 'vim-scripts/ReplaceWithRegister'

Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
call plug#end()

nnoremap <SPACE> <Nop>
let mapleader=" "

" allow unsaved background buffers and remember marks/undo for them
set hidden

" remember more commands and search history
set history=10000

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

" Access colors present in 256 colorspace
set termguicolors
set background=dark
let base16colorspace=256
colorscheme base16-default-dark

" trigger `autoread` when files changes on disk
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" notification after file change
autocmd FileChangedShellPost *
\ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" Clear highlighting on esc
nnoremap <Esc><Esc> :<C-u>nohlsearch<CR>

" Auto-trim trailing whitespace
autocmd BufWritePre * :silent! %s/\s\+$//e

" mkdir -p when saving
au BufWritePre,FileWritePre * silent! call mkdir(expand('<afile>:p:h'), 'p')

" current line highlight
let g:conoline_color_normal_dark = 'ctermbg=236'

let g:deoplete#enable_at_startup = 1

" language servers
let g:LanguageClient_serverCommands = {
    \ 'ruby': ['solargraph', 'stdio'],
    \ }

nmap <silent> gd <Plug>(lcn-definition)

nnoremap <silent> <leader>p :FZF<cr>

" search
nnoremap <silent> <leader>ff :Rg<cr>

" window navigation
nnoremap <silent> <M-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <M-j> :TmuxNavigateDown<cr>
nnoremap <silent> <M-k> :TmuxNavigateUp<cr>
nnoremap <silent> <M-l> :TmuxNavigateRight<cr>
nnoremap <silent> <leader>x :bd<cr>
nnoremap <silent> <Tab> :bnext<cr>
nnoremap <silent> <S-Tab> :bprevious<cr>

" yanking/pasting to system register
nmap <silent> <M-y> "+y
nmap <silent> <M-y> "+y
vmap <silent> <M-y> "+y
vmap <silent> <M-y> "+y
map Y y$
nmap <silent> <M-p> "+p
vmap <silent> <M-p> "+p
nmap <silent> <M-P> "+P
vmap <silent> <M-P> "+P
