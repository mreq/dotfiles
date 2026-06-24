#!/bin/bash

set -e

echo "setup/ubuntu/app-neovim - Installing Neovim packages"
sudo apt install -y neovim luarocks tree-sitter-cli

if [[ "$(command -v nvim)" == "/usr/local/bin/nvim" ]]; then
	echo "setup/ubuntu/app-neovim - /usr/local/bin/nvim shadows Ubuntu's package"
	echo "setup/ubuntu/app-neovim - Remove it manually if the packaged nvim should be used"
fi

echo "setup/ubuntu/app-neovim - ✓"
