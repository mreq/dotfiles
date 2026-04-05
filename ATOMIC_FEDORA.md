# Fedora Atomic Sway Migration Plan

Goal: clone dotfiles, run `config/install.sh`, reboot, be ready to develop.

---

## Architecture

```
Host (immutable)   Fedora Sway Atomic base — add nothing if possible
                   rpm-ostree: fuse2 only (for AppImages, may be eliminable)

Toolbox            tmux, btop, ripgrep
                   foot launches directly into toolbox tmux session

Flatpak            Chrome, Slack, Spotify, Thunderbird, KeePassXC

Tarball/AppImage   Sublime Text (official tarball), Cursor (AppImage),
                   Double Commander (AppImage), lazygit (binary)
                   all managed via update_* scripts in bin/

Podman             Per-project dev services (postgres, redis, etc.)
                   Devcontainers for "clone and develop" workflow

systemd (user)     ssh-agent.socket, podman.socket
```

No global runtimes. No mise. No toolbox for dev — projects use devcontainers.

---

## Repo Structure

### Drop
```
config/alacritty/
config/electron/
config/input/
config/kitty/
config/mise/
config/ruby/
CHANGES.md
```

### Keep
```
config/btop/
config/cursor/          keybindings.json, settings.json, cursor.sh, cursor.desktop
config/doublecmd/       doublecmd.xml, shortcuts.scf
config/foot/            foot.ini  (shell= line changes, see Phase 1b)
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
bin/spotify/
bin/sway/
```

### New
```
bin/sublime/update_sublime
bin/lazygit/update_lazygit
bin/doublecmd/update_doublecmd
config/sublime/sublime.desktop
```

### Rewrite
```
config/install.sh
config/bash/.bashrc
config/bash/.profile
```

---

## Implementation Phases

### Phase 1 — Host layer

The Fedora Sway Atomic spin ships sway, foot, rofi, waybar, grim, slurp,
polkit-gnome, wl-clipboard, brightnessctl, playerctl, wob, wlsunset, swaync.
Verify what's present before adding anything.

Only confirmed addition:
```
rpm-ostree install fuse2
```

fuse2 is required for AppImages. If `--appimage-extract-and-run` works reliably
for both Cursor and Double Commander, this layer can be eliminated entirely.

Reboot after any rpm-ostree changes.

### Phase 1b — Toolbox

```
toolbox create dev
toolbox run --container dev dnf install -y tmux btop ripgrep
```

foot.ini — change shell so every foot window lands in toolbox tmux:
```ini
shell=toolbox run --container dev tmux
```

### Phase 2 — Flatpak

```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install flathub \
  com.google.Chrome \
  com.slack.Slack \
  com.spotify.Client \
  org.mozilla.Thunderbird \
  org.keepassxc.KeePassXC
```

### Phase 2b — Tarball / AppImage apps

All managed via update_* scripts. Pattern established by `bin/cursor/update_cursor`.

**Cursor** — AppImage, existing script unchanged
- Download `Cursor-*.AppImage` to `~/Downloads`, run `update_cursor`
- `cursor.sh` wraps with `ELECTRON_OZONE_PLATFORM_HINT=auto --no-sandbox`
- Needs Podman socket exported (Phase 3) for devcontainer support

**Sublime Text** — official tarball from sublimetext.com
- `bin/sublime/update_sublime` — consider auto-download via Sublime's update API
  rather than manual download, since the endpoint is public and stable
- Extracts to `~/.local/share/sublime-text/`, symlink at `~/.local/bin/subl`
- `config/sublime/sublime.desktop` — custom desktop file

**lazygit** — single binary from GitHub releases
- `bin/lazygit/update_lazygit` — auto-download from GitHub releases API
- Installs to `~/.local/bin/lazygit`
- Available in toolbox automatically via shared home directory

**Double Commander** — Qt AppImage from GitHub releases
- `bin/doublecmd/update_doublecmd`
- Installs to `~/.local/share/doublecmd/`, symlink at `~/.local/bin/doublecmd`
- Custom `.desktop` file for Sway/rofi integration

### Phase 3 — systemd user services

```
systemctl --user enable --now ssh-agent.socket
systemctl --user enable --now podman.socket
```

### Phase 4 — install.sh rewrite

Order of operations:
1. rpm-ostree install (Phase 1)
2. toolbox setup (Phase 1b)
3. flatpak install (Phase 2)
4. symlink dotfiles configs
5. install fonts
6. systemctl enable services (Phase 3)

Symlink changes vs current install.sh:
- Remove: nvim, mise, ruby/.gemrc, electron/electron-flags.conf
- Adjust: Sublime config path TBD (Flatpak vs tarball config location differs)
- Add: `config/sublime/sublime.desktop` → `~/.local/share/applications/`
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
- `dropbox start -i` — evaluate: Flatpak Dropbox or remove if replaced
- Rest should work as-is

**bindsym.conf**
- App launchers reference direct binaries (`google-chrome`, `subl`, etc.)
  Verify Flatpak installs provide these wrappers in PATH, otherwise use
  `flatpak run com.google.Chrome` etc.

**bin/sway/ scripts**
- Should work as-is, verify dependencies present on Fedora Sway spin

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

Confirm Sublime Text LSP works with devcontainers via:
```json
"command": ["podman", "exec", "-i", "<container>", "ruby-lsp"]
```

If Sublime's sandbox (if Flatpak) or exec path causes issues, fall back to tarball.
Cursor devcontainers handle LSP natively — no extra config needed.

---

## Open Questions

- [ ] fuse2 host layer: test `--appimage-extract-and-run` for Cursor + Double Commander first
- [ ] Dropbox: keep (Flatpak) or replace?
- [ ] `update_sublime`: manual download pattern or auto-download via update API?
- [ ] Sublime LSP + devcontainer exec: test before committing to approach
- [ ] Podman socket + Cursor devcontainers: verify compatibility
- [ ] Team devcontainer adoption: prototype first, then propose
