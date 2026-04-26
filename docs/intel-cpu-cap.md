# Intel CPU Cap

Keep Dell `balanced` mode responsive while reducing fan-triggering turbo spikes.
`max_perf_pct` is runtime-only, so persist it with systemd.

Tested on a Dell Latitude 7520 with an Intel Core i7-1185G7.

```bash
sudoedit /etc/systemd/system/cpu-max-perf.service
```

```ini
[Unit]
Description=Cap Intel CPU max performance percentage

[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c 'echo 80 > /sys/devices/system/cpu/intel_pstate/max_perf_pct'

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cpu-max-perf.service
```

Check:

```bash
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct
```

Undo:

```bash
sudo systemctl disable --now cpu-max-perf.service
echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
```

## Turbo

Keep turbo enabled first; the 80% cap usually reduces fan spikes without making
short interactive work sluggish.

```bash
cat /sys/devices/system/cpu/intel_pstate/no_turbo
```

`0` means turbo is enabled. If the cap is still too noisy:

```bash
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```

To disable turbo persistently, add it to the same service:

```ini
ExecStart=/usr/bin/bash -c 'echo 80 > /sys/devices/system/cpu/intel_pstate/max_perf_pct; echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'
```

Re-enable turbo:

```bash
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```
