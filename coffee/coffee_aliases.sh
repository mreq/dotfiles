# Browsersync livereload server
bs() {
  if [[ $2 ]]; then
    files="$2"
  else
    files="**"
  fi
  browser-sync start --no-notify --no-ghost-mode --tunnel --proxy "localhost:$1" --files "$files" || notify-send -i /home/petr/Dropbox/ubuntu_one/icons/browser-sync.png 'browser-sync' 'crashed'
}
