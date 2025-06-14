#!/bin/bash

set -e

# if current user not in video group, add them
if ! groups | grep -q "\bvideo\b"; then
    echo "Adding current user to video group..."
    sudo usermod -aG video "$USER"
fi
