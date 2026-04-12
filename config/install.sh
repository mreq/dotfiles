#!/bin/bash
# Symlink dotfiles configs into ~/. Idempotent.
# Pair with setup/install.sh (or run via the repo-root install.sh) for distro setup.

set -e

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "${0%/*}" || exit 0

create_symlink() {
	if ! test -h "$2" || ! test -e "$2"; then
		echo "Creating symlink: $1 -> $2"
		rm -rf "$2" && mkdir -p "$(dirname "$2")" && ln -s "$1" "$2"
	fi
}

create_dotfiles_config_symlink() {
	create_symlink "$DOTFILES_ROOT/config/$1" "$2"
}

create_dotfiles_config_symlink bash/.bashrc ~/.bashrc
create_dotfiles_config_symlink bash/.profile ~/.profile

create_dotfiles_config_symlink btop ~/.config/btop

create_dotfiles_config_symlink dunst ~/.config/dunst

create_dotfiles_config_symlink git/.gitconfig ~/.gitconfig
create_dotfiles_config_symlink git/ignore ~/.config/git/ignore

create_dotfiles_config_symlink doublecmd/doublecmd.xml ~/.config/doublecmd/doublecmd.xml
create_dotfiles_config_symlink doublecmd/shortcuts.scf ~/.config/doublecmd/shortcuts.scf

create_dotfiles_config_symlink foot ~/.config/foot

create_dotfiles_config_symlink gtk/gtk-3.0 ~/.config/gtk-3.0
create_dotfiles_config_symlink gtk/gtk-4.0 ~/.config/gtk-4.0
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'

create_dotfiles_config_symlink lazygit ~/.config/lazygit

create_dotfiles_config_symlink mimeapps/mimeapps.list ~/.config/mimeapps.list

create_dotfiles_config_symlink rofi ~/.config/rofi

create_dotfiles_config_symlink sway ~/.config/sway

create_dotfiles_config_symlink tmux/.tmux.conf ~/.tmux.conf

create_dotfiles_config_symlink waybar ~/.config/waybar

create_dotfiles_config_symlink zed ~/.config/zed

# systemd user units (enabled by setup/install.sh)
create_dotfiles_config_symlink systemd/dropbox.service ~/.config/systemd/user/dropbox.service
create_dotfiles_config_symlink systemd/wlsunset.service ~/.config/systemd/user/wlsunset.service

create_dotfiles_config_symlink cursor/keybindings.json ~/.config/Cursor/User/keybindings.json
create_dotfiles_config_symlink cursor/settings.json ~/.config/Cursor/User/settings.json
create_dotfiles_config_symlink cursor/cursor.sh ~/.local/bin/cursor
create_dotfiles_config_symlink cursor/cursor.desktop ~/.local/share/applications/cursor.desktop

(
	cd sublime-text || exit 0

	for dir in Packages/User*; do
		create_dotfiles_config_symlink sublime-text/"$dir" ~/.config/sublime-text/"$dir"
	done
)

if [[ ! -d ~/.local/share/fonts ]]; then
	mkdir -p ~/.local/share/fonts
	echo "Creating ~/.local/share/fonts"
fi

FONT_PATH=~/.local/share/fonts/FiraCodeNerdFontMono-Regular.ttf

if [[ ! -f "$FONT_PATH" ]]; then
	cp ../fonts/FiraCodeNerdFontMono-Regular.ttf "$FONT_PATH"
	echo "Copying FiraCodeNerdFontMono-Regular to ~/.local/share/fonts"
fi
