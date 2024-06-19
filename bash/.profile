test -z "$PROFILEREAD" && . /etc/profile || true

set -o vi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

for dir in $HOME/.dotfiles/*/bin; do
  PATH="$PATH:$dir"
done

export VISUAL=nvim
export EDITOR="$VISUAL"
export BUNDLER_EDITOR="subl -n"

# Manage ssh-agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
  ssh-agent > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi

if [[ ! "$SSH_AUTH_SOCK" ]]; then
  source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# rbenv setup
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
