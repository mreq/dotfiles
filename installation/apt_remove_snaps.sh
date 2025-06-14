#!/bin/bash

set -e

# add mozilla ppa
sudo add-apt-repository -y ppa:mozillateam/ppa

# prioritize apt for thunderbird
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: thunderbird
Pin: version 2:1snap*
Pin-Priority: -1
' | sudo tee /etc/apt/preferences.d/thunderbird

# prioritize apt for firefox
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox
Pin: version 2:1snap*
Pin-Priority: -1
' | sudo tee /etc/apt/preferences.d/firefox

sudo snap remove firefox
sudo snap remove thunderbird

sudo apt update
sudo apt install -y --allow-downgrades firefox thunderbird
