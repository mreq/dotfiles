#!/bin/bash

set -e

curl https://mise.run | sh
mise install node
mise install ruby
