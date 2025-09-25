#!/bin/bash

set -e

if ! command -v mise &> /dev/null; then
  echo "setup/ubuntu/app-mise - Running mise install script"
  curl https://mise.run | sh

  echo "setup/ubuntu/app-mise - Running mise install node"
  mise install node

  echo "setup/ubuntu/app-mise - Running mise install ruby"
  mise install ruby
fi

echo -e "setup/ubuntu/app-mise - ✓"
