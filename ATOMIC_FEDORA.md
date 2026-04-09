# Fedora Atomic Sway Migration Plan

Goal: clone dotfiles, run `config/install.sh`, reboot, be ready to develop.

---

## Architecture

```
Host (immutable)   Fedora Sway Atomic base
                   rpm-ostree layer: distrobox, tmux, btop, ripgrep
                   fuse2 already present in base image (AppImages work out of the box)

Distrobox "apps"   Fedora-based, exported to host via distrobox-export
(Fedora)           google-chrome-stable, slack, sublime-text, keepassxc,
                   firefox, thunderbird, doublecmd-gtk, freelens

Distrobox "dev"    Fedora-based, exported to host via distrobox-export
(Fedora)           gh, awscli2, wf-recorder — future dev/tools go here

Flatpak            Spotify (no official repo, low-risk),
                   GIMP (verified, non-sensitive)

AppImage           Cursor, Freelens — managed via generic update_appimage script
Binary             lazygit — managed via update_lazygit script

Podman             Per-project dev services (postgres, redis, etc.)
                   Devcontainers for "clone and develop" workflow

systemd (user)     ssh-agent.socket, podman.socket
```

No global runtimes. No mise. No toolbox — add later only if needed.
Projects use devcontainers for dev environments.

Layering rationale: only distrobox, tmux, btop, ripgrep, python3-i3ipc are
layered — bare essentials for host use. distrobox and python3-i3ipc are not
shipped with the Sway spin. python3-i3ipc is needed by bin/sway/ scripts.
Everything else runs in distroboxes or Flatpak to keep the host image
minimal and rollbacks fast.

Distrobox rationale: all critical desktop apps (Chrome, Slack, Sublime,
Firefox, Thunderbird, KeePassXC) run in the "apps" distrobox. Fedora-based
for newer packages. distrobox-export creates seamless .desktop files and
binaries in ~/.local/bin — sway keybindings and rofi work transparently.
Dev CLI tools (gh, awscli2) live in a separate "dev" distrobox to keep
concerns separated.

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
bin/update_appimage            generic AppImage installer (reads packages.json)
bin/lazygit/update_lazygit
config/systemd/dropbox.service
config/systemd/wlsunset.service
bin/waybar/check_updates
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

## Implementation Steps

Work happens on the `atomic-fedora` branch. Commit after each step.

### Step 0 — Repo cleanup

Delete dropped files and directories:
```
config/alacritty/
config/electron/
config/input/
config/kitty/
config/mise/
config/nvim/           (already staged for deletion)
config/ruby/
config/bash/.bash_aliases
bin/spotify/
CHANGES.md
```

Commit: "feat(fedora): drop unused configs"

### Step 1 — Fix existing configs

Small, targeted edits to existing files:
- `config/tmux/.tmux.conf`: `xclip -in -selection clipboard` → `wl-copy`
- `config/sway/config.d/exec.conf`: remove `dropbox start -i` and `wlsunset` lines
- `config/bash/.bashrc`: clean sweep (source /etc/bashrc + exports)
- `config/bash/.profile`: clean sweep (PATH + EDITOR)

Commit: "feat(fedora): update configs for atomic"

### Step 2 — Create new files

- `config/systemd/dropbox.service`
- `config/systemd/wlsunset.service`
- `bin/waybar/check_updates`
- `bin/lazygit/update_lazygit`
- `bin/doublecmd/update_doublecmd`

Commit: "feat(fedora): add systemd services and update scripts"

### Step 3 — Rewrite install.sh

Encode the full setup: rpm-ostree, distrobox (apps + dev), flatpak (Spotify),
symlinks, systemd enable, fonts. This is the "clone and run" automation.

Commit: "feat(fedora): rewrite install.sh"

### Step 4 — Test on live system

Run `config/install.sh` on the current system. Fix anything that breaks.
This step may produce follow-up commits.

### Step 5 — Sway keybinding audit

Verify all app launchers work with layered/Flatpak/AppImage binaries.
Update `bindsym.conf` as needed. Move Dropbox URL files to private repo,
update paths.

Commit: "feat(fedora): update sway bindings"

### Step 6 — Devcontainer prototype

Separate from dotfiles — done in a project repo.
Once working, document the approach here for reference.

### Step 7 — Merge to master

Squash or merge `atomic-fedora` → `master` when everything works.

---

## Phase Details

### Host layer

The Fedora Sway Atomic spin ships sway, foot, rofi, waybar, grim, slurp,
wl-clipboard, brightnessctl, playerctl, wlsunset, swaylock, swayidle,
wpctl, dunst, thunar, xwayland.
NOT shipped: wob, swaync, polkit-gnome, wf-recorder, ssh-askpass.

Remove layered Firefox (replaced by distrobox Firefox):
```
rpm-ostree override remove firefox
```

Layer only bare essentials for host use:
```
rpm-ostree install distrobox tmux btop ripgrep python3-i3ipc openssh-askpass
```

fuse2 is already in the base image — AppImages work without layering anything.

Reboot after rpm-ostree changes.

### Distrobox

Both containers are Fedora-based (newer packages than Ubuntu).

**"apps" container** — desktop apps without verified Flatpaks:
```
distrobox create --name apps --image registry.fedoraproject.org/fedora-toolbox:latest
distrobox enter apps -- sudo dnf install -y \
  google-chrome-stable slack sublime-text keepassxc firefox thunderbird doublecmd-gtk
```

Requires adding vendor repos inside the container for Chrome, Slack, Sublime.

Export apps to host (creates .desktop files + binaries in ~/.local/bin):
```
distrobox enter apps -- distrobox-export --app google-chrome-stable
distrobox enter apps -- distrobox-export --app slack
distrobox enter apps -- distrobox-export --app sublime_text
distrobox enter apps -- distrobox-export --app keepassxc
distrobox enter apps -- distrobox-export --app firefox
distrobox enter apps -- distrobox-export --app thunderbird
distrobox enter apps -- distrobox-export --app doublecmd
```

**"dev" container** — CLI dev tools:
```
distrobox create --name dev --image registry.fedoraproject.org/fedora-toolbox:latest
distrobox enter dev -- sudo dnf install -y gh awscli2
```

Export binaries to host:
```
distrobox enter dev -- distrobox-export --bin /usr/bin/gh --export-path ~/.local/bin
distrobox enter dev -- distrobox-export --bin /usr/bin/aws --export-path ~/.local/bin
```

### Flatpak

Only Spotify — no official repo or deb available.

```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.spotify.Client
```

Chrome stays as the default browser for now — the `--app=` flag is used
heavily in sway keybindings. Switch to Firefox later if needed.

### AppImage / binary apps

All AppImages and binaries are declared in `setup/packages.json` under
`appimage` and `binary` keys.

**`bin/update_appimage`** — generic script that handles all AppImages:
- Reads app config from packages.json (source, pattern, install dir)
- `source: "github"` — auto-downloads latest from GitHub releases API
- `source: "manual"` — picks up from `~/Downloads` (e.g. Cursor has no
  public release URL)
- Version comparison, symlink to latest, old version cleanup
- Usage: `update_appimage cursor` or `update_appimage freelens`

**Cursor** — `source: manual`, download AppImage to ~/Downloads first
- `cursor.sh` wraps with `ELECTRON_OZONE_PLATFORM_HINT=auto --no-sandbox`
- Needs Podman socket exported for devcontainer support

**Freelens** — `source: github`, auto-download from freelensapp/freelens

**lazygit** — single binary from GitHub releases
- `bin/lazygit/update_lazygit` — auto-download from GitHub releases API
- Installs to `~/.local/bin/lazygit`
- Preferred over Fedora COPR (third-party repo) — official binary is more reliable

### systemd user services

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

**Automatic update check** (system-level, not user):
```
sudo systemctl enable --now rpm-ostreed-automatic.timer
```

Waybar custom module in `config/waybar/config.jsonc`:
```json
"custom/updates": {
    "exec": "~/.dotfiles/bin/waybar/check_updates",
    "return-type": "json",
    "interval": 3600
}
```

`bin/waybar/check_updates` — shows icon when rpm-ostree update available,
empty otherwise.

### install.sh rewrite

All package names, container images, services, etc. are defined in
`setup/packages.json` — install.sh reads from it, nothing is hardcoded.

**Idempotent by design.** Every section checks current state before acting.
Edit `packages.json`, re-run the script, and only the delta is applied.

Order of operations:
1. rpm-ostree override remove + install (from `rpm-ostree` key) — requires reboot
2. distrobox create + dnf install + distrobox-export (from `distrobox` key)
3. flatpak install (from `flatpak` key)
4. symlink dotfiles configs
5. install fonts
6. systemctl enable services (from `systemd-user` key)

Idempotency approach per section:
- **rpm-ostree**: query `rpm-ostree status` for currently layered/removed
  packages, compute diff against packages.json, skip if no changes
- **distrobox**: check if container exists (`distrobox list`), create only
  if missing. Inside container: `rpm -q` to check installed packages,
  `dnf install` only missing ones. Re-export apps/bins unconditionally
  (export is already idempotent)
- **flatpak**: `flatpak list` to check installed, install only missing
- **symlinks**: `ln -sf` is already idempotent
- **fonts**: skip if font dir already populated
- **systemd**: `systemctl is-enabled` to check, enable only if not already

Symlink changes vs current install.sh:
- Remove: nvim, mise, ruby/.gemrc, electron/electron-flags.conf, zed Flatpak path
- Remove: Sublime tarball desktop file (no longer needed — distrobox-export handles it)
- Keep: everything else as-is

### Bash clean sweep

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

### Sway config cleanup

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

### Devcontainer prototype

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

### Editor + LSP

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
- [ ] Distrobox app exports: verify GUI apps (Chrome, Sublime, etc.) integrate cleanly with sway/rofi
- [ ] Distrobox persistence: confirm containers survive rpm-ostree updates/reboots
