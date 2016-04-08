if &compatible
  set nocompatible
endif
"----------------------------------------
" dein setup:
set runtimepath^=~/.vim/dein.vim/repos/github.com/Shougo/dein.vim
call dein#begin(expand('~/.vim/dein.vim'))
call dein#add('Shougo/dein.vim')
"----------------------------------------
" Add or remove your plugins here:
call dein#add('Shougo/deoplete.nvim')
" call dein#add('morhetz/gruvbox')
call dein#add('vim-airline/vim-airline')
call dein#add('vim-airline/vim-airline-themes')
call dein#add('tpope/vim-surround')
call dein#add('tpope/vim-fugitive')
call dein#add('tomtom/tcomment_vim')
call dein#add('scrooloose/nerdtree')
call dein#add('AndrewRadev/switch.vim')
call dein#add('ctrlpvim/ctrlp.vim')
call dein#add('benekastah/neomake')
call dein#add('chriskempson/base16-vim')
"----------------------------------------
call dein#add('kchmck/vim-coffee-script', { 'on_ft': 'coffee' })
call dein#add('tpope/vim-markdown', { 'on_ft': 'markdown' })
"----------------------------------------
call dein#end()
"----------------------------------------
" Required:
filetype plugin indent on
"----------------------------------------
" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif
"End dein Scripts-------------------------
"----------------------------------------

" 256 color terminal
let &t_Co=256
let base16colorspace=256

" Change leader key
let mapleader=" "

" Enable syntax highlight
syntax on

" Enable numbers
set number relativenumber

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
colorscheme base16-eighties
set cursorline

" Airline setup
set noshowmode
let g:airline#extensions#tabline#enabled = 1
set hidden
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#show_tab_nr = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='base16'

" Autocomplete
let g:deoplete#enable_at_startup = 1

" switch.vim setup
let g:switch_mapping = 'gs'

" CtrlP setup
let g:ctrlp_map = '<Leader>p'
let g:ctrlp_show_hidden = 1
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/.sass-cache/*

nnoremap ; :
nnoremap ;; q:
nnoremap <Leader>j :bprevious<CR>
nnoremap <Leader>k :bnext<CR>
nnoremap <Leader>s :w<CR>
nnoremap <Leader>x :b#<bar>bd#<CR>
nnoremap <Leader>q :bufdo bd<CR>

" Dark/light switch
nnoremap <F12> :let &background = ( &background == "dark"? "light" : "dark" )<CR>

" Reload config
nnoremap <Leader>rr :so $MYVIMRC<CR>
nnoremap <Leader>ev :e ~/.vimrc<CR>

" Hide Highlight
nnoremap <Leader>hh :noh<CR>

" Git keybinds
nnoremap <Leader>gs :Gstatus<CR>

" Splits/window management
nnoremap <Leader>wj <C-w>S<C-w>j
nnoremap <Leader>wl <C-w>v<C-w>l
nnoremap <M-h> <C-w>h
nnoremap <M-j> <C-w>j
nnoremap <M-k> <C-w>k
nnoremap <M-l> <C-w>l
nnoremap <M-o> <C-w>_

