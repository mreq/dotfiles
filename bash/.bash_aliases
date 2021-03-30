alias R='R --no-save -q'

alias be="bundle exec"
alias bi="bundle install"
alias bo="bundle open"

alias n="nvim"

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