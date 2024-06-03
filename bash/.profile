test -z "$PROFILEREAD" && . /etc/profile || true

set -o vi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

for dir in $HOME/.dotfiles/*/bin; do
  PATH="$PATH:$dir"
done

export EDITOR=/usr/bin/vim
