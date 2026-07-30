# Codex Bubblewrap on Ubuntu

Codex uses the system Bubblewrap executable for its Linux sandbox. This
repository manages the Ubuntu package and the narrow AppArmor exception that
lets `/usr/bin/bwrap` create the user namespace it needs.

## Setup

Run the normal setup script:

```bash
setup/setup.sh
```

The `bubblewrap` package declares `apparmor` as a subpackage. After package
provisioning, its hook manages `/etc/apparmor.d/usr.bin.bwrap`, reloads that
profile, and checks that Bubblewrap can start a minimal sandbox. Re-running
setup is safe: the hook replaces and reloads the profile only when its content
differs, so an already-correct setup does not need `sudo`. If validation fails
(for example, after AppArmor has restarted), the hook reloads the profile and
validates again.

## Validate

```bash
bwrap --ro-bind / / true
codex sandbox -- true
```

Both commands should exit successfully without output. The Codex updater runs
the second check after each upgrade and points back to `setup/setup.sh` if the
host sandbox is not usable.

## Why use the Ubuntu package?

Codex prefers a system `bwrap` when one is available. Keeping Bubblewrap under
APT leaves security updates to Ubuntu and ensures that its AppArmor policy
matches `/usr/bin/bwrap`. The updater intentionally downloads only Codex, not
a release-provided Bubblewrap binary.

## Troubleshooting

If the hook still fails, collect these values before investigating the host
policy:

```bash
which bwrap
bwrap --version
sysctl kernel.unprivileged_userns_clone
sysctl kernel.apparmor_restrict_unprivileged_userns
```

Do not use `--dangerously-bypass-approvals-and-sandbox` as a workaround. It
disables both the sandbox and approval controls instead of repairing the host
setup.
