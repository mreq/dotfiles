alias R='R --no-save -q'

alias b="btop"

alias be="bundle exec"
alias bi="bundle install --jobs $( nproc )"
alias bo="bundle open"

alias g="lazygit"

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

wrg() {
  ( cd ~/work; rg -g *.$1 "${*:2}" )
}

n() {
  # get title from arg or current directory
  title="${1:-$(basename "$(pwd)")}"
  kitty --hold --app-id kitty-nvim --detach --title "nvim - $title" -- nvim "${@:2}" || {
    echo "Failed to start kitty with nvim"
    return 1
  }
}
