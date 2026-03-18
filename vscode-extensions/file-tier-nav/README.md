# File Tier Nav

Navigate between related files by **tiers** (e.g. alpha, beta, gamma, delta). Each tier is bound to a key; only rules in that tier run, so e.g. “alpha” can be rb/slim only and never open sass/js.

Rules are regex **from** → **to** path templates (with `$1`, `$2`, …). The extension does **not** ship default keybindings or rules; you configure everything in settings and `keybindings.json`. Examples below are for copy-paste.

## Configuration

### Tiers

In `settings.json` (or workspace settings), define your tiers:

```json
"fileTierNav.tiers": [
  { "id": "alpha" },
  { "id": "beta" },
  { "id": "gamma" },
  { "id": "delta" }
]
```

You can add `"key": "ctrl+space"` etc. per tier for your own documentation; the extension does not use it.

### Rules

Each rule has:

- **id** – unique name
- **from** – array of regexes matching the current file path (workspace-relative). Try each in order, first match wins; its capture groups are used for **to**.
- **to** – array of path templates. Use `$1`, `$2`, … for capture groups. Try each in order, open first that exists; if none and `create: true`, create the last.
- **tier** – tier id. Only rules in the invoked tier run.
- **create** – (optional, default `false`) If the target file does not exist and `create` is true, create it and open it.
- **replace** – (optional, default `false`) If true, open the target in the current tab (replacing the active editor). By default the target opens in a new tab in the same group (or focuses its tab if already open), using `preview: false` so it does not replace the current tab.
- **split** – (optional, default `false`) If true, open the target in a new column (split editor).

Rule order matters: the first matching rule in the tier wins.

## Example: keybindings

In `keybindings.json`, bind the command `fileTierNav.open` with a tier in args (one key per tier):

```json
[
  {
    "key": "ctrl+space",
    "command": "fileTierNav.open",
    "args": { "tier": "alpha" }
  },
  {
    "key": "ctrl+backspace",
    "command": "fileTierNav.open",
    "args": { "tier": "delta" }
  },
  {
    "key": "ctrl+shift+space",
    "command": "fileTierNav.open",
    "args": { "tier": "beta" }
  },
  {
    "key": "ctrl+shift+alt+space",
    "command": "fileTierNav.open",
    "args": { "tier": "gamma" }
  }
]
```

## Example: Rails view components

Tiers: **alpha** = rb ↔ slim (including from test file); **beta** = sass ↔ slim (create sass if missing, works from test); **gamma** = js ↔ slim (create js if missing, works from test); **delta** = test ↔ rb (both directions).

**Settings** (`fileTierNav.tiers` as above, and `fileTierNav.rules`):

```json
"fileTierNav.rules": [
  {
    "id": "to_ruby_component_rb_from_test",
    "from": ["test/components/(.+/)?([^/]+)_component_test\\.rb"],
    "to": ["app/components/$1$2_component.rb"],
    "tier": "delta"
  },
  {
    "id": "to_ruby_component_test",
    "from": ["app/components/(.+/)?([^/]+)_component\\..+"],
    "to": ["test/components/$1$2_component_test.rb"],
    "tier": "delta"
  },
  {
    "id": "to_ruby_view_component_sass",
    "from": ["(app|test)/components/(.+/)?([^/]+)_component(?:\\.(?!sass|scss)\\w+|_test\\.rb)"],
    "to": ["app/components/$2$3_component.scss", "app/components/$2$3_component.sass"],
    "tier": "beta",
    "create": true
  },
  {
    "id": "to_ruby_view_component_slim_from_sass",
    "from": ["(app|test)/components/(.+/)?([^/]+)_component\\.(sass|scss)"],
    "to": ["app/components/$2$3_component.slim"],
    "tier": "beta"
  },
  {
    "id": "to_ruby_view_component_js",
    "from": ["(app|test)/components/(.+/)?([^/]+)_component(?:\\.(?!js)\\w+|_test\\.rb)"],
    "to": ["app/components/$2$3_component.js"],
    "tier": "gamma",
    "create": true
  },
  {
    "id": "to_ruby_view_component_slim_from_js",
    "from": ["(app|test)/components/(.+/)?([^/]+)_component\\.js"],
    "to": ["app/components/$2$3_component.slim"],
    "tier": "gamma"
  },
  {
    "id": "to_ruby_view_component_slim",
    "from": ["app/components/(.+/)?([^/]+)_component\\.(?!slim)"],
    "to": ["app/components/$1$2_component.slim"],
    "tier": "alpha"
  },
  {
    "id": "to_ruby_view_component_rb",
    "from": ["(test|app)/components/(.+/)?([^/]+)_component(?:\\.\\w+|_test\\.rb)"],
    "to": ["app/components/$2$3_component.rb"],
    "tier": "alpha"
  }
]
```

Paths are workspace-relative (e.g. `app/components/.../foo_component.rb` or `test/components/.../foo_component_test.rb`). Rules that start with `(app|test)/components/` use `$2` = path prefix and `$3` = base name; rules that start with `app/components/` or `test/components/` use `$1` = path prefix and `$2` = base name. The first matching rule in the tier wins; its **to** path is opened (or created when `create: true`).

## Loading from dotfiles (symlink)

To use the extension from a folder in your dotfiles (e.g. `vscode-extensions/file-tier-nav/`), symlink it into the Cursor (or VS Code) extensions directory:

```bash
ln -s ~/.dotfiles/vscode-extensions/file-tier-nav ~/.cursor/extensions/mreq.file-tier-nav-0.1.0
```

Replace `0.1.0` with the version in `package.json`. Reload the window after code changes.
