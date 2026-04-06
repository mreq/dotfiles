# Fedora Atomic Sway Migration Plan

Goal: clone dotfiles, run `config/install.sh`, reboot, be ready to develop.

---

## Architecture

```
Host (immutable)   Fedora Sway Atomic base
                   rpm-ostree layer: tmux, btop, ripgrep, google-chrome-stable,
                     slack, sublime-text, keepassxc
                   rpm-ostree override remove: firefox (replaced by Flatpak)
                   fuse2 already present in base image (AppImages work out of the box)

Flatpak            Firefox (verified, Mozilla), Thunderbird (verified, Mozilla),
                   Spotify (unverified, low-risk)

AppImage           Cursor, Double Commander — managed via update_* scripts
Binary             lazygit — managed via update_* script

Podman             Per-project dev services (postgres, redis, etc.)
                   Devcontainers for "clone and develop" workflow

systemd (user)     ssh-agent.socket, podman.socket
```

No global runtimes. No mise. No toolbox — add later only if needed.
Projects use devcontainers for dev environments.

Layering rationale: Chrome, Slack, Sublime, KeePassXC are security-critical
or core workflow apps. All available from official vendor rpm repos with GPG
signing. Layering leaf apps has negligible impact on updates and rollback.

---

## Repo Structure

### Drop
```
config/alacritty/
config/electron/
config/input/
config/kitty/
config/mise/
config/nvim/
config/ruby/
CHANGES.md
```

### Keep
```
config/btop/
config/cursor/          keybindings.json, settings.json, cursor.sh, cursor.desktop
config/doublecmd/       doublecmd.xml, shortcuts.scf
config/foot/            foot.ini
config/git/
config/gtk/
config/lazygit/
config/mimeapps/
config/rofi/
config/sublime-text/    Packages/User*
config/sway/
config/tmux/            .tmux.conf  (xclip → wl-copy)
config/vscode-extensions/
config/waybar/
config/zed/
fonts/
bin/cursor/             update_cursor (unchanged)
bin/foot/
bin/sway/
```

### New
```
bin/lazygit/update_lazygit
bin/doublecmd/update_doublecmd
config/systemd/dropbox.service
config/systemd/wlsunset.service
```

### Rewrite
```
config/install.sh
config/bash/.bashrc
config/bash/.profile
```

### Remove
```
config/bash/.bash_aliases
bin/spotify/            (playerctl handles media controls now)
```

---

## Implementation Phases

### Phase 1 — Host layer

The Fedora Sway Atomic spin ships sway, foot, rofi, waybar, grim, slurp,
polkit-gnome, wl-clipboard, brightnessctl, playerctl, wob, wlsunset, swaync.
Verify what's present before adding anything.

Remove layered Firefox, replace with Flatpak:
```
rpm-ostree override remove firefox
```

Add official vendor repos for Chrome, Slack, Sublime, then layer:
```
rpm-ostree install \
  tmux btop ripgrep keepassxc \
  google-chrome-stable slack sublime-text
```

fuse2 is already in the base image — AppImages work without layering anything.

Reboot after rpm-ostree changes.

### Phase 2 — Flatpak

```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install flathub \
  org.mozilla.firefox \
  org.mozilla.Thunderbird \
  com.spotify.Client
```

Chrome stays as the default browser for now — the `--app=` flag is used
heavily in sway keybindings. Switch to Firefox later if needed.

### Phase 2b — AppImage / binary apps

Pattern established by `bin/cursor/update_cursor`.

**Cursor** — AppImage, existing script unchanged
- Download `Cursor-*.AppImage` to `~/Downloads`, run `update_cursor`
- `cursor.sh` wraps with `ELECTRON_OZONE_PLATFORM_HINT=auto --no-sandbox`
- Needs Podman socket exported (Phase 3) for devcontainer support

**Double Commander** — Qt AppImage from GitHub releases
- `bin/doublecmd/update_doublecmd`
- Installs to `~/.local/share/doublecmd/`, symlink at `~/.local/bin/doublecmd`
- Custom `.desktop` file for Sway/rofi integration

**lazygit** — single binary from GitHub releases
- `bin/lazygit/update_lazygit` — auto-download from GitHub releases API
- Installs to `~/.local/bin/lazygit`

### Phase 3 — systemd user services

Already provided by the system:
```
systemctl --user enable --now ssh-agent.socket
systemctl --user enable --now podman.socket
```

Custom services in `config/systemd/`, symlinked to `~/.config/systemd/user/`:

**dropbox.service** — background file sync daemon
```ini
[Unit]
Description=Dropbox

[Service]
ExecStart=%h/.local/share/.dropbox-dist/dropboxd
Restart=on-failure

[Install]
WantedBy=default.target
```

**wlsunset.service** — day/night color temperature
```ini
[Unit]
Description=Day/night color temperature
After=graphical-session.target

[Service]
ExecStart=wlsunset -l 50.08 -L 14.42
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

Everything else in sway `exec.conf` is tightly coupled to sway
(wob uses $SWAYSOCK, swaync, polkit) and stays there.

### Phase 4 — install.sh rewrite

Order of operations:
1. rpm-ostree override remove + install (Phase 1) — requires reboot
2. flatpak install (Phase 2)
3. symlink dotfiles configs
4. install fonts
5. systemctl enable services (Phase 3)

Symlink changes vs current install.sh:
- Remove: nvim, mise, ruby/.gemrc, electron/electron-flags.conf, zed Flatpak path
- Remove: Sublime tarball desktop file (no longer needed — rpm handles it)
- Keep: everything else as-is

### Phase 5 — Bash clean sweep

Drop all Ubuntu-era content. Start from Fedora defaults.

**`.bashrc`**
```bash
source /etc/bashrc

export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
export PATH="$HOME/.local/bin:$PATH"
```

**`.profile`**
```bash
# Add dotfiles bin dirs to PATH
for dir in $HOME/.dotfiles/*/bin; do
  PATH="$PATH:$dir"
done

export EDITOR="subl"
export BUNDLER_EDITOR="subl -n"
```

No `.bash_aliases` for now — add only when a need arises.

### Phase 6 — Sway config cleanup

**exec.conf**
- Remove `dropbox start -i` (now systemd service)
- Remove `wlsunset` (now systemd service)
- Rest should work as-is

**bindsym.conf**
- `$mod+1`: change to `firefox` (now default browser, layered via Flatpak)
- `$mod+x`, `$mod+z`, `$mod+w`: Dropbox URL references → move URL files
  to a private git repo, update paths
- Verify all layered/Flatpak apps provide expected binary names in PATH

**bin/sway/ scripts**
- Should work as-is, verify dependencies present on Fedora Sway spin

**bin/spotify/play_pause**
- Can be removed — `bindsym.conf` already uses `playerctl` for media keys

**tmux/.tmux.conf**
- Change `xclip -in -selection clipboard` → `wl-copy`

### Phase 7 — Devcontainer prototype

Add `.devcontainer/` to one project as a prototype. If it works, propose to team.

Structure:
```
.devcontainer/
  devcontainer.json     editor config, extensions, port forwarding
  docker-compose.yml    app service + postgres + redis
  Dockerfile            dev image: ruby + system deps (not production Dockerfile)
```

Key points:
- `postCreateCommand: bundle install && rails db:prepare`
- ruby-lsp extension declared in devcontainer.json — installs automatically
- `.env` workflow unchanged: copy `.env.sample`, fill in secrets, works as-is
- `rails test`, `rails db:migrate` etc. run in Cursor's integrated terminal (inside container)
- foot+tmux access via: `podman exec -it <container> bash`

### Phase 8 — Editor + LSP

Sublime Text is layered (rpm) so it has full host access. LSP integration
with devcontainers via:
```json
"command": ["podman", "exec", "-i", "<container>", "ruby-lsp"]
```

Cursor devcontainers handle LSP natively — no extra config needed.

---

## Dropbox

Official headless daemon, installed from Dropbox directly (no Flatpak):

```bash
curl -L "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - -C ~/.local/share/
```

Runs as `~/.local/share/.dropbox-dist/dropboxd`. Keep the existing
`exec dropbox start -i` in sway `exec.conf` or create a systemd user service.

The sway keybinding URL files (`calendar_urls.txt`, `code_urls.txt`,
`whatsapp_urls.txt`) currently in `~/Dropbox/dotfiles/` move to a separate
private git repo — removes the Dropbox dependency from the desktop setup.
Dropbox still syncs for personal use.

---

## Open Questions

- [x] fuse2: already in base image, no action needed
- [ ] Podman socket + Cursor devcontainers: verify compatibility
- [ ] Team devcontainer adoption: prototype first, then propose
- [ ] Dropbox: verify headless daemon works on Atomic
- [ ] Default browser: switch to Firefox later if `--app=` usage can be replaced
