#!/bin/bash

set -e

cd "${0%/*}" || exit 0

create_symlink() {
  if ! test -h $2 || ! test -e $2; then
    echo "Creating symlink: $1 -> $2"
    rm -rf $2 && mkdir -p $(dirname $2) && ln -s $1 $2
  fi
}

create_dotfiles_config_symlink() {
  create_symlink ~/.dotfiles/config/$1 $2
}

create_dotfiles_config_symlink alacritty ~/.config/alacritty

create_dotfiles_config_symlink bash/.bashrc ~/.bashrc
create_dotfiles_config_symlink bash/.bash_aliases ~/.bash_aliases
create_dotfiles_config_symlink bash/.profile ~/.profile

create_dotfiles_config_symlink btop ~/.config/btop

create_dotfiles_config_symlink git/.gitconfig ~/.gitconfig
create_dotfiles_config_symlink git/ignore ~/.config/git/ignore

create_dotfiles_config_symlink doublecmd/doublecmd.xml ~/.config/doublecmd/doublecmd.xml
create_dotfiles_config_symlink doublecmd/shortcuts.scf ~/.config/doublecmd/shortcuts.scf

create_dotfiles_config_symlink electron/electron-flags.conf ~/.config/electron-flags.conf

create_dotfiles_config_symlink gtk/gtk-3.0 ~/.config/gtk-3.0

create_dotfiles_config_symlink input/.inputrc ~/.inputrc

create_dotfiles_config_symlink lazygit ~/.config/lazygit

create_dotfiles_config_symlink mimeapps/mimeapps.list ~/.config/mimeapps.list

create_dotfiles_config_symlink mise ~/.config/mise

create_dotfiles_config_symlink nvim ~/.config/nvim

create_dotfiles_config_symlink rofi ~/.config/rofi

create_dotfiles_config_symlink ruby/.gemrc ~/.gemrc

create_dotfiles_config_symlink sway ~/.config/sway

create_dotfiles_config_symlink tmux/.tmux.conf ~/.tmux.conf

create_dotfiles_config_symlink waybar ~/.config/waybar

create_dotfiles_config_symlink zed ~/.config/zed

(
  cd sublime-text || exit 0

  for dir in Packages/User*; do
    create_dotfiles_config_symlink sublime-text/$dir ~/.config/sublime-text/$dir
  done
)

# Dropbox symlinks
if [[ -d ~/Dropbox/ubuntu ]]; then
  create_symlink ~/Dropbox/dotfiles/AppImages ~/AppImages
  create_symlink ~/Dropbox/dotfiles/fonts ~/.fonts
  create_symlink ~/Dropbox/dotfiles/tex/texmf ~/texmf
  create_symlink ~/Dropbox/Pictures/unsplash ~/Pictures/unsplash
  create_symlink ~/Dropbox/Pictures/unsplash_hd ~/Pictures/unsplash_hd
else
  echo "Dropbox not present - not creating Dropbox symlinks."
fi
