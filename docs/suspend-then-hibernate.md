# Suspend then hibernate

This is the tested hibernation setup for Ubuntu 26.04 on a ThinkPad T14 Gen 1
AMD with an encrypted ext4 root filesystem on LUKS and LVM.

The resulting behavior on a machine that supports suspend-then-hibernate is:

1. A Sway power action or lid close suspends the laptop to RAM.
2. After one hour, systemd wakes it using an RTC timer, writes the hibernation
   image to swap, and powers it off.
3. Pressing the power button, or opening the lid when the firmware supports
   that action, starts the laptop.
4. After the LUKS unlock, the previous session is restored behind swaylock.

## Firmware

In UEFI setup, keep `Config > Power > Lid Sensor` enabled. The lid sensor is
required for lid-close events and may also start this ThinkPad from
hibernation when the lid is opened. Treat power-on-on-open as a firmware
feature: it is independent of systemd and Sway.

The useful end-to-end test is to close the lid, leave it closed for more than
one hour, and then open it. If the firmware does not start it, the power button
will; resume itself is unaffected.

## Swap file and resume path

The tested setup uses a 32 GiB `/swap.img`. A separate swap partition is not
needed. The kernel supports a non-contiguous swap file, but it must know both
the block device containing the file and the swap file's first physical
offset.

If the swap file needs to be rebuilt at that size, first make sure no
hibernation image is pending, then recreate and activate it:

```bash
sudo swapoff /swap.img
sudo rm -- /swap.img
sudo fallocate -l 32G /swap.img
sudo chmod 0600 /swap.img
sudo mkswap /swap.img
sudo swapon /swap.img
```

Keep this entry in `/etc/fstab`:

```fstab
/swap.img none swap sw 0 0
```

For this storage stack, the resume device is the root logical volume, not the
outer LUKS partition and not the swap file:

```text
/dev/mapper/ubuntu--vg-ubuntu--lv
```

After creating, resizing, moving, or restoring `/swap.img`, recalculate its
offset before testing hibernation:

```bash
sudo filefrag -v /swap.img
```

On this ext4 filesystem, use the `physical_offset` at logical offset zero as
`resume_offset`. Do not retain an offset from an earlier swap file.

Add the resume parameters in `/etc/default/grub.d/99-hibernate.cfg`, replacing
`OFFSET` with the current value:

```bash
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX resume=/dev/mapper/ubuntu--vg-ubuntu--lv resume_offset=OFFSET"
```

Ensure dracut includes its resume module in
`/etc/dracut.conf.d/99-hibernate.conf`:

```bash
add_dracutmodules+=" resume "
```

Then rebuild the boot configuration and the initramfs and reboot:

```bash
sudo update-grub
sudo dracut --force --kver "$(uname -r)"
sudo reboot
```

After reboot, verify that the resume device is no longer `0:0` and that the
configured offset reached the kernel:

```bash
cat /proc/cmdline
cat /sys/power/resume
cat /sys/power/resume_offset
```

## Ubuntu authorization

Ubuntu may deliberately deny hibernation through a vendor polkit rule even
when the kernel resume path is valid. A local rule in
`/etc/polkit-1/rules.d/10-enable-hibernate.rules` can authorize active local
members of the `sudo` group:

```javascript
polkit.addRule(function (action, subject) {
    if (action.id.indexOf("org.freedesktop.login1.hibernate") === 0 &&
        subject.active && subject.local && subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
```

Check the result without attempting to sleep:

```bash
busctl call \
  org.freedesktop.login1 \
  /org/freedesktop/login1 \
  org.freedesktop.login1.Manager \
  CanHibernate

busctl call \
  org.freedesktop.login1 \
  /org/freedesktop/login1 \
  org.freedesktop.login1.Manager \
  CanSuspendThenHibernate
```

Both should return `s "yes"` for the logged-in user.

## One-hour delay and lid close

The repository contains the tested systemd drop-ins at:

- `config/systemd/sleep.conf.d/80-suspend-then-hibernate.conf`
- `config/systemd/logind.conf.d/80-suspend-then-hibernate.conf`

Install copies in `/etc`; do not symlink early-boot system configuration into
a user home directory:

```bash
sudo install -D -m 0644 \
  config/systemd/sleep.conf.d/80-suspend-then-hibernate.conf \
  /etc/systemd/sleep.conf.d/80-suspend-then-hibernate.conf

sudo install -D -m 0644 \
  config/systemd/logind.conf.d/80-suspend-then-hibernate.conf \
  /etc/systemd/logind.conf.d/80-suspend-then-hibernate.conf
```

### How the `sleep` action selects an operation

`sleep` is a systemd-logind action added in systemd 256. It is not a shell
alias and does not name one particular kernel sleep state. It asks logind to
select a supported operation from the candidates in `SleepOperation`.

This drop-in limits those candidates to:

```ini
SleepOperation=suspend-then-hibernate suspend
```

systemd checks sleep operations in a fixed priority order. Of the two enabled
here, suspend-then-hibernate is checked first and regular suspend second. The
lid path is therefore:

```text
lid closes
  -> HandleLidSwitch=sleep
  -> systemd-logind selects an operation
     -> suspend-then-hibernate, when supported
     -> suspend, otherwise
```

When suspend-then-hibernate is selected, systemd starts by suspending to RAM.
It arranges an RTC wakeup and, after `HibernateDelaySec=1h`, wakes only far
enough to write the hibernation image and power off. A normal user wakeup
before the timer expires returns directly from suspend and cancels that
transition.

`systemctl sleep` submits the same policy-selected action to logind. The Sway
script below performs its own explicit capability check instead so it also
works with systemd releases older than 256.

Reboot to apply the logind change without disrupting the current graphical
session. `HandleLidSwitchDocked` is intentionally left at systemd's default of
`ignore`, so closing the lid does not suspend while docked or using an external
display.

After reboot, verify the effective configuration:

```bash
systemd-analyze cat-config systemd/sleep.conf
systemd-analyze cat-config systemd/logind.conf

busctl get-property \
  org.freedesktop.login1 \
  /org/freedesktop/login1 \
  org.freedesktop.login1.Manager \
  HandleLidSwitch
```

The Sway power selector and system mode menu share one action. It checks the
login manager first:

```bash
busctl call \
  org.freedesktop.login1 \
  /org/freedesktop/login1 \
  org.freedesktop.login1.Manager \
  CanSuspendThenHibernate
```

Only `s "yes"` selects `systemctl suspend-then-hibernate`; every other result,
an unavailable D-Bus call, or an older systemd falls back to `systemctl
suspend`. The menu action keeps its `suspend` label because that remains the
portable result on other machines.

The lid drop-in requires systemd 256 or newer because that is when the `sleep`
action and `SleepOperation` were added.

## Testing

First test hibernation directly. Store the boot ID in the same interactive
shell before hibernating:

```bash
before=$(cat /proc/sys/kernel/random/boot_id)
systemctl hibernate
```

Power the laptop on, unlock LUKS, return to that shell, and compare:

```bash
printf 'before: %s\nafter:  %s\n' \
  "$before" \
  "$(cat /proc/sys/kernel/random/boot_id)"
```

Matching IDs prove that the old kernel and userspace were restored rather than
a fresh boot merely reaching the same applications.

Only after direct hibernation works, test the combined operation:

```bash
systemctl suspend-then-hibernate
```

For a short test, temporarily reduce `HibernateDelaySec`, reboot, and restore
it to `1h` after the transition succeeds.

Useful logs after resume:

```bash
journalctl -b -u systemd-suspend-then-hibernate.service
journalctl -b -k | rg -i 'PM:|hibernate|resume|amdgpu|nvme|iwlwifi'
```

## Maintenance

- Recalculate `resume_offset` whenever `/swap.img` is recreated, moved,
  resized, or restored from backup.
- Rebuild GRUB and the initramfs after changing the resume device or offset.
- Re-test direct hibernation after major kernel, firmware, storage, or
  encryption changes.
- Do not modify or mount the hibernated root filesystem from another boot
  before resuming it.

## References

- [systemd sleep configuration](https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html)
- [systemd login manager configuration](https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html)
- [Linux kernel swap-file hibernation documentation](https://docs.kernel.org/power/swsusp-and-swap-files.html)
- [Lenovo T14 Gen 1 Linux user guide](https://download.lenovo.com/pccbbs/mobiles_pdf/t14_t15_p14s_p15s_user_guide_linux.pdf)
