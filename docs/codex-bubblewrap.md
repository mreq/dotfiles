# Codex Bubblewrap on Ubuntu 24.04

## Symptom

Codex file edits repeatedly ask to retry without the sandbox:

```text
Would you like to make the following edits?

Reason: command failed; retry without sandbox?
```

The standalone sandbox test fails with:

```bash
codex sandbox linux -- true
```

```text
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
```

## Diagnosis

On Ubuntu 24.04, AppArmor can restrict unprivileged user namespaces. Codex uses
Bubblewrap for the Linux sandbox, and Bubblewrap needs user/network namespace
setup.

Useful checks:

```bash
which bwrap
bwrap --version
sysctl kernel.unprivileged_userns_clone
sysctl kernel.apparmor_restrict_unprivileged_userns
```

Expected values from the fixed machine:

```text
/usr/bin/bwrap
bubblewrap 0.9.0
kernel.unprivileged_userns_clone = 1
kernel.apparmor_restrict_unprivileged_userns = 1
```

If `kernel.apparmor_restrict_unprivileged_userns = 1`, add a targeted
AppArmor profile for Bubblewrap instead of disabling the restriction globally.

## Fix

Create `/etc/apparmor.d/usr.bin.bwrap`:

```bash
sudo tee /etc/apparmor.d/usr.bin.bwrap >/dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,

  include if exists <local/bwrap>
}
EOF
```

Load the profile:

```bash
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.bwrap
```

Validate:

```bash
bwrap --ro-bind / / true
codex sandbox linux -- true
```

No output from both commands means success.

## Notes

This fix does not bypass Codex approvals. It only lets Bubblewrap create the
sandbox that Codex is already configured to use. Command confirmations still
follow Codex's approval policy and persisted prefix rules in:

```text
~/.codex/rules/default.rules
```

Avoid switching to `--dangerously-bypass-approvals-and-sandbox` for this issue;
that disables both the sandbox and approvals.
