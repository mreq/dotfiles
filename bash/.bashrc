# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

# Use emacs keybindings
set -o emacs

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the history file, don't overwrite it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# History setup
# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=5000000

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
  shopt -s "$option" 2> /dev/null
done
unset option

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
  else
	color_prompt=
  fi
fi

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/[\1] /'
}

if [ "$color_prompt" = yes ]; then
  PS1='\[\033[7;30;43m\]$(parse_git_branch)\[\033[00m\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='$(parse_git_branch)${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
*)
  ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  if test -r ~/.dircolors; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi

  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
fi

# fix xfce4-terminal colors (256)
if [ "$COLORTERM" == "xfce4-terminal" ]; then
  export TERM=xterm-256color
  # if [[ -f "$HOME/.dotfiles/bash/base16-shell/base16-default.dark.sh" ]]; then
  #   source "$HOME/.dotfiles/bash/base16-shell/base16-default.dark.sh"
  # fi
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# Alias for clipboard
alias clipboard='xclip -sel clip'
alias peg='ps -aux | grep '
alias R='R --no-save -q'
alias sudo='sudo '
alias connect_android='adb forward tcp:9222 localabstract:chrome_devtools_remote'
alias dmenu_custom="dmenu -i -b -l 10 -nb '#242424' -nf white -sb '#2e557e' -fn 'Ubuntu Mono-12'"
alias rmux="tmux new 'R --no-save'"
alias nette-fix="[ -d temp/cache/ ] && [ -f composer.json ] && rm -rf temp/cache/* && composer install"
alias be="bundle exec"
alias bi="bundle install"
alias bo="bundle open"
alias bs="bin/server"
alias fs="foreman start"
alias mpc="mina production console"
alias mpd="mina production deploy"
alias mps="mina production ssh"
alias msc="mina staging console"
alias msd="mina staging deploy"
alias mss="mina staging ssh"
alias tmux="TERM=screen-256color-bce tmux"
alias xfce4-terminal-tmux="xfce4-terminal --maximize --command=tmux"
alias htop="TERM=screen htop"

alias gc="git clone"
alias gs="git status"
alias ga="git add -p"
alias gd="git diff"
alias gdc="git diff --cached"
alias gp="git push"
alias gu="git pull --rebase"

terminal-colors() {
  for x in 0 1 4 5 7 8; do for i in $( seq 30 37 ); do for a in $( seq 40 47 ); do echo -ne "\e[$x;$i;$a""m\\\e[$x;$i;$a""m\e[0;37;40m "; done; echo; done; done; echo ""
}

shle_prepare() {
  export STAGING_AWS_ACCESS_KEY_ID=$( grep aws_access_key_id ~/.aws/credentials | awk '{ print $3 }' )
  export STAGING_AWS_SECRET_ACCESS_KEY=$( grep aws_secret_access_key ~/.aws/credentials | awk '{ print $3 }' )
  export SHLE_DEFAULT_PASSWORD=$( cat ~/.shle_default_password )
}

r() {
  if [[ -f bin/rails ]]; then
    bin/rails "$@"
  else
    rails "$@"
  fi
}

rr() {
  if [[ -f bin/rake ]]; then
    bin/rake "$@"
  else
    rake "$@"
  fi
}

e() {
  if [[ -f bin/ember ]]; then
    bin/ember "$@"
  else
    ember "$@"
  fi
}

export VISUAL=nvim
export EDITOR="$VISUAL"
export BUNDLER_EDITOR="subl -n"

export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).
# Override NODE_PATH for yeoman
export NODE_PATH=$N_PREFIX:"$N_PREFIX/lib/node_modules"

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Bash completions
find ~/.dotfiles/ -name "*_completions.sh" -exec bash -c {} \;

export FZF_DEFAULT_COMMAND='pt -g "" --hidden'
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# exports
[[ -s "$HOME/.bash_exports" ]] && source "$HOME/.bash_exports"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [ -d ~/Android/Sdk ]; then
  export ANDROID_HOME=~/Android/Sdk
  export PATH=${PATH}:${ANDROID_HOME}/tools
  export PATH=${PATH}:${ANDROID_HOME}/platform-tools
fi

if [ -d ~/Applications/android-studio/jre ]; then
  export JAVA_HOME=~/Applications/android-studio/jre
fi
