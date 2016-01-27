# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
  # include .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
  fi
fi

PATH="$PATH:$HOME/scripts/bin"

# Add NPM to PATH for scripting
PATH="$PATH:$HOME/.local/share/npm/bin"

export N_PREFIX="$HOME/n";
PATH="$PATH:$N_PREFIX/bin"

export EDITOR=vim

# Add RVM to PATH for scripting
export PATH="$PATH:$HOME/.rvm/bin"
