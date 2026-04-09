#!/bin/bash
# Top-level installer for the dotfiles.
#
# Order matters:
#   1. config/install.sh — symlinks dotfiles into ~/, including custom systemd
#                          unit files that the next step expects to find.
#   2. setup/install.sh  — distro setup: rpm-ostree, distrobox, flatpak,
#                          systemd-user services.

set -e

REPO_DIR="$(dirname "$(readlink -f "$0")")"

bash "$REPO_DIR/config/install.sh"
bash "$REPO_DIR/setup/install.sh"
