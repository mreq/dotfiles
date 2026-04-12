# ~/.profile: executed for login shells.

# Source .bashrc if running bash
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# Add user's private bin to PATH
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Add dotfiles bin dirs to PATH
for dir in "$HOME/.local/share/dotfiles"/*/bin; do
  [ -d "$dir" ] && PATH="$PATH:$dir"
done

export VISUAL=subl
export EDITOR=subl
export BUNDLER_EDITOR="subl -n"
