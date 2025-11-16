# Flatpak Migration Guide

This document describes the migration from apt/snap packages to Flatpak for desktop applications.

## Overview

The following applications have been migrated to Flatpak:

- **Desktop Applications**: GIMP, Inkscape, LibreOffice, KeepassXC, VLC, nomacs, Double Commander
- **Web & Communication**: Google Chrome, Spotify, Slack, Firefox, Thunderbird

## Installation

Flatpak applications are installed automatically when you run:

```bash
~/.dotfiles/setup/setup.sh
```

Or manually:

```bash
~/.dotfiles/setup/ubuntu/app-flatpak.sh
```

## Profile Migration

### Firefox

If you're migrating from apt/snap Firefox to Flatpak Firefox, you'll need to migrate your profile:

1. **Locate your current profile**:
   - Apt version: `~/.mozilla/firefox/`
   - Snap version: `~/snap/firefox/common/.mozilla/firefox/`

2. **Copy profile to Flatpak location**:
   ```bash
   # Find your profile directory (usually has a random name)
   PROFILE_DIR=$(ls -d ~/.mozilla/firefox/*.default* 2>/dev/null | head -1)
   
   # Copy to Flatpak location
   mkdir -p ~/.var/app/org.mozilla.firefox/data/firefox
   cp -r "$PROFILE_DIR" ~/.var/app/org.mozilla.firefox/data/firefox/
   ```

3. **Alternative: Use symlink** (if you want to share the same profile):
   ```bash
   # Remove Flatpak profile directory
   rm -rf ~/.var/app/org.mozilla.firefox/data/firefox
   
   # Create symlink to your existing profile
   ln -s ~/.mozilla/firefox ~/.var/app/org.mozilla.firefox/data/firefox
   ```

### Thunderbird

Similar process for Thunderbird:

1. **Locate your current profile**:
   - Apt version: `~/.thunderbird/`
   - Snap version: `~/snap/thunderbird/common/.thunderbird/`

2. **Copy profile to Flatpak location**:
   ```bash
   # Find your profile directory
   PROFILE_DIR=$(ls -d ~/.thunderbird/*.default* 2>/dev/null | head -1)
   
   # Copy to Flatpak location
   mkdir -p ~/.var/app/org.mozilla.Thunderbird/data/thunderbird
   cp -r "$PROFILE_DIR" ~/.var/app/org.mozilla.Thunderbird/data/thunderbird/
   ```

3. **Alternative: Use symlink**:
   ```bash
   rm -rf ~/.var/app/org.mozilla.Thunderbird/data/thunderbird
   ln -s ~/.thunderbird ~/.var/app/org.mozilla.Thunderbird/data/thunderbird
   ```

## Sway Configuration Changes

### App-IDs

The Sway configuration has been updated to support both old and new app-ids for backward compatibility:

- `doublecmd` → `org.doublecmd.DoubleCommander`
- `thunderbird` → `org.mozilla.Thunderbird`
- `spotify` → `com.spotify.Client`
- `Slack` → `com.slack.Slack`
- `Gimp` → `org.gimp.GIMP`
- `google-chrome` → `com.google.Chrome`
- `firefox` → `org.mozilla.firefox`

### Keybindings

All keybindings have been updated to use `flatpak run` commands. The old app-ids are still supported for compatibility during transition.

## Removing Old Packages

After verifying that Flatpak versions work correctly, you can remove the old packages:

### Remove apt packages:
```bash
sudo apt remove gimp inkscape libreoffice-calc libreoffice-writer keepassxc vlc nomacs doublecmd-qt
sudo apt autoremove
```

### Remove snap packages:
```bash
sudo snap remove firefox thunderbird slack
```

### Remove Chrome .deb (if installed):
```bash
sudo apt remove google-chrome-stable
```

### Remove Spotify apt repository:
```bash
sudo rm /etc/apt/sources.list.d/spotify.list
sudo rm /etc/apt/trusted.gpg.d/spotify.gpg
sudo apt update
```

## Updating Flatpak Applications

To update all Flatpak applications:

```bash
flatpak update -y
```

To update a specific application:

```bash
flatpak update -y org.mozilla.firefox
```

## Automatic Updates

You can set up automatic Flatpak updates by creating a cron job:

```bash
# Add to ~/.dotfiles/cron/update-flatpaks
#!/bin/bash
flatpak update -y --noninteractive
```

Then symlink it:

```bash
sudo ln -s ~/.dotfiles/cron/update-flatpaks /etc/cron.weekly/update-flatpaks
```

## Troubleshooting

### App-ID Detection

If Sway keybindings don't work, check the actual app-id:

```bash
# Run the Flatpak app
flatpak run org.mozilla.firefox

# In another terminal, check what Sway sees:
swaymsg -t get_tree | grep -A 5 -B 5 firefox
```

Update the app-id in `config/sway/config.d/assigns.conf` and `config/sway/config.d/bindsym.conf` if needed.

### File Associations

If file associations don't work, you may need to set them manually:

```bash
# Set Firefox as default browser
xdg-settings set default-web-browser org.mozilla.firefox.desktop

# Set Thunderbird as default mail client
xdg-mime default org.mozilla.Thunderbird.desktop x-scheme-handler/mailto
```

### Permission Issues

Some Flatpak apps may need additional permissions. Check and grant permissions:

```bash
# List permissions for an app
flatpak info org.mozilla.firefox

# Grant filesystem access (example)
flatpak override --user --filesystem=home org.mozilla.firefox
```

## Benefits of Flatpak

- **Newer versions**: Get latest features faster
- **Isolation**: Apps don't interfere with system packages
- **Consistency**: Same versions across different distributions
- **Easy updates**: Single command to update all apps
- **Rollback**: Can revert to previous versions if needed

## Configuration Files

Flatpak applications store their configuration in:

- `~/.var/app/<app-id>/config/` - Configuration files
- `~/.var/app/<app-id>/data/` - Application data

Your existing dotfiles symlinks should continue to work, but some apps may need their configs copied to the Flatpak directories.

