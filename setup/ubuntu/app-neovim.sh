#!/bin/bash

set -e

install_nvim() {
  echo -e "setup/ubuntu/app-neovim - Installing Neovim"
  cd /tmp

  wget -O nvim.tar.gz "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
  tar -xf nvim.tar.gz

  sudo install nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

  sudo cp -R nvim-linux-x86_64/lib /usr/local/
  sudo cp -R nvim-linux-x86_64/share /usr/local/

  rm -rf nvim-linux-x86_64 nvim.tar.gz
  cd -

  echo -e "setup/ubuntu/app-neovim - Installing luarocks and tree-sitter-cli to resolve lazyvim :checkhealth warnings"
  sudo apt install -y luarocks tree-sitter-cli
}

if ! command -v nvim &> /dev/null; then
  install_nvim
else
  nvim_version=$(nvim --version | head -n 1 | awk '{print $2}')

  # if version not equal v0.11.2
  if [[ "$nvim_version" != "v0.11.2" ]]; then
    echo "setup/ubuntu/app-neovim - Neovim version is $nvim_version, uninstalling"
    sudo apt remove -y neovim
    sudo rm -rf /usr/local/bin/nvim

    install_nvim
  fi
fi

echo -e "setup/ubuntu/app-neovim - ✓"
