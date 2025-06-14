#!/bin/bash

set -e

# Check if zellij is already installed
if [ -x "$HOME/.local/bin/zellij" ]; then
  echo "Zellij is already installed in $HOME/.local/bin."
  exit 0
fi

# Store the current directory
START_DIR="$PWD"

# Temporary directory for downloading
TMP_DIR="/tmp/zellij_install"
mkdir -p "$TMP_DIR"

# Navigate to the temporary directory
cd "$TMP_DIR"

# Download the latest Zellij release
wget https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz

# Extract the tarball
tar -xzf zellij-x86_64-unknown-linux-musl.tar.gz

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Move the binary to ~/.local/bin
mv zellij "$HOME/.local/bin/zellij"

# Clean up
rm -rf "$TMP_DIR"

# Return to the original directory
cd "$START_DIR"

echo "Zellij installed successfully in $HOME/.local/bin!"
