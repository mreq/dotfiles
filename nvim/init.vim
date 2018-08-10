if &compatible
  set nocompatible
endif
"----------------------------------------
" dein setup:
set runtimepath^=~/.config/nvim/dein.vim/repos/github.com/Shougo/dein.vim
call dein#begin(expand('~/.config/nvim/dein.vim'))
call dein#add('Shougo/dein.vim')

"----------------------------------------
" Utility
call dein#add('Shougo/unite.vim')
call dein#add('Shougo/neoyank.vim')
call dein#add('Shougo/vimproc.vim', { 'build': 'make' })
call dein#add('tpope/vim-surround')
call dein#add('tomtom/tcomment_vim')
call dein#add('terryma/vim-multiple-cursors')
call dein#add('maxbrunsfeld/vim-yankstack')
call dein#add('tpope/vim-sleuth')
call dein#add('tpope/vim-unimpaired')
call dein#add('tpope/vim-abolish')
call dein#add('tpope/vim-repeat')

" call dein#add('fntlnz/atags.vim')
call dein#add('tsukkee/unite-tag')
call dein#add('christoomey/vim-tmux-navigator')
call dein#add('ap/vim-buftabline')
call dein#add('vim-scripts/ReplaceWithRegister')
call dein#add('tpope/vim-eunuch')

" Autocomplete
call dein#add('Shougo/deoplete.nvim')
call dein#add('SirVer/ultisnips')

" Text objects
call dein#add('kana/vim-textobj-user')
call dein#add('michaeljsmith/vim-indent-object')
call dein#add('glts/vim-textobj-comment')
call dein#add('kana/vim-textobj-line')
call dein#add('lucapette/vim-textobj-underscore')
call dein#add('jasonlong/vim-textobj-css')
call dein#add('nelstrom/vim-textobj-rubyblock')

" Git
call dein#add('tpope/vim-fugitive')

" File nav
call dein#add('scrooloose/nerdtree')
call dein#add('junegunn/fzf')

" Linters, etc.
call dein#add('benekastah/neomake')

" Colors
call dein#add('chriskempson/base16-vim')
call dein#add('w0ng/vim-hybrid')

" Syntax specific
call dein#add('kchmck/vim-coffee-script', { 'on_ft': 'coffee' })
call dein#add('lukaszkorecki/CoffeeTags', { 'on_ft': 'coffee' })
call dein#add('tpope/vim-markdown', { 'on_ft': 'markdown' })
call dein#add('vim-scripts/vim-emblem')
call dein#add('slim-template/vim-slim')
call dein#add('othree/yajs.vim')
call dein#add('mxw/vim-jsx')

"----------------------------------------
call dein#end()
"----------------------------------------
filetype plugin indent on
"----------------------------------------
if dein#check_install()
  call dein#install()
endif
"----------------------------------------

" allow unsaved background buffers and remember marks/undo for them
set hidden

" remember more commands and search history
set history=10000

" 256 color terminal
let &t_Co=256

" Fix garbage characters appearing in xfce4-terminal
let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0

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

" Display incomplete command
set showcmd

" Always display the status line
set laststatus=2

" Disable swap file
set noswapfile

" Searching tweaks
set gdefault
set ignorecase
set smartcase
set hlsearch
set incsearch
set showmatch

" Auto-trim trailing whitespace
autocmd BufWritePre * :silent! %s/\s\+$//e

" " Auto tag generation
" autocmd BufWritePost * call atags#generate()

" mkdir -p when saving
au BufWritePre,FileWritePre * silent! call mkdir(expand('<afile>:p:h'), 'p')

" Access colors present in 256 colorspace
let base16colorspace=256
" Set color scheme
set background=dark
colorscheme hybrid
set cursorline

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

" Autocomplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#tag#cache_limit_size = 50000000

" Tab for autocomplete
inoremap <expr><tab> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><s-tab> pumvisible() ? "\<C-p>" : "\<TAB>"

" switch.vim setup
let g:switch_mapping = 'gs'

" fzf setup
set rtp+=~/.fzf
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/.sass-cache/*

" run vim-jsx for *.js as well
let g:jsx_ext_required = 0

" Unite settings
if executable('pt')
  let g:unite_source_grep_command = 'pt'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor'
  let g:unite_source_grep_recursive_opt = ''
  let g:unite_source_grep_encoding = 'utf-8'
endif

" Function - window zoom toggle
function! s:ZoomToggle() abort
  if exists('t:zoomed') && t:zoomed
    execute t:zoom_winrestcmd
    let t:zoomed = 0
  else
    let t:zoom_winrestcmd = winrestcmd()
    resize
    vertical resize
    let t:zoomed = 1
  endif
endfunction
command! ZoomToggle call s:ZoomToggle()

nnoremap <Leader>j :bprevious<CR>
nnoremap <Leader>k :bnext<CR>
nnoremap <Leader>s :w<CR>
nnoremap <Leader><Leader> :w<CR>
nnoremap <Leader>x :b#<bar>bd#<CR>
nnoremap <Leader>q :q<CR>

nnoremap j gj
nnoremap k gk

" Insert mode movement
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>

" File management
nnoremap <Leader>fx :call delete(expand('%')) \| bdelete!<CR>
nnoremap <Leader>fu :saveas expand('%')

" Search
nnoremap <silent> <Leader>ff :<C-u>Unite grep:. -buffer-name=search-buffer<CR>
nnoremap <silent> <Leader>p :FZF<CR>

" Dark/light switch
nnoremap <F12> :let &background = ( &background == "dark"? "light" : "dark" )<CR>

" Reload config
nnoremap <Leader>rr :so $MYVIMRC<CR>
nnoremap <Leader>fv :e ~/.config/nvim/init.vim<CR>

" NERDTree
nnoremap <Leader>l :NERDTreeToggle<CR>

" Hide Highlight
nnoremap <Esc><Esc> :noh<CR>

" Git keybinds
nnoremap <Leader>gs :Gstatus<CR><C-w>o
nnoremap <Leader>gl :Glog<CR>
autocmd BufRead fugitive* map <buffer> q :Gstatus<CR><C-w>o

" Splits/window management
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <M-h> :TmuxNavigateLeft<CR>
nnoremap <silent> <M-j> :TmuxNavigateDown<CR>
nnoremap <silent> <M-k> :TmuxNavigateUp<CR>
nnoremap <silent> <M-l> :TmuxNavigateRight<CR>
nnoremap <silent> <M-\> :TmuxNavigatePrevious<CR>
nnoremap <Leader>wj <C-w>S<C-w>j
nnoremap <Leader>wl <C-w>v<C-w>l
nnoremap <Leader>z :ZoomToggle<CR>
nnoremap <Leader>bx :%bd<CR>
nnoremap <M-d> :Unite buffer<CR>

" tags
nnoremap <Leader>e :Unite -start-insert tag:%<CR>
nnoremap <Leader>t :Unite -start-insert tag<CR>

" yanking
nmap <silent> <M-y> "+y
vmap <silent> <M-y> "+y
map Y y$
let g:unite_source_history_yank_enable = 1
nnoremap <Leader>y :Unite history/yank<cr>

" abbreviations
cabbr <expr> %% expand('%:p:h')
