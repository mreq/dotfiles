#!/bin/bash

set -e

# Only run on Dell laptops
if ! grep -qi "dell" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
	echo "setup/ubuntu/app-dell-fan-control - Skipping (not a Dell laptop)"
	exit 0
fi

echo "setup/ubuntu/app-dell-fan-control - Setting up Dell fan control"

NEEDS_SUDO=false
DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
I8KMON_CONF="$DOTFILES_DIR/config/dell-fan-control/i8kmon.conf"

# Check what needs to be done
if ! command -v i8kmon &>/dev/null; then
	NEEDS_SUDO=true
fi

if [ ! -f /etc/modprobe.d/dell-smm-hwmon.conf ]; then
	NEEDS_SUDO=true
fi

if ! grep -q "dell_smm_hwmon" /etc/modules 2>/dev/null; then
	NEEDS_SUDO=true
fi

if [ -f "$I8KMON_CONF" ] && ! diff -q "$I8KMON_CONF" /etc/i8kmon.conf &>/dev/null; then
	NEEDS_SUDO=true
fi

if [ ! -f /etc/systemd/system/i8kmon.service ]; then
	NEEDS_SUDO=true
fi

if ! lsmod | grep -q dell_smm_hwmon; then
	NEEDS_SUDO=true
fi

# Exit early if nothing to do
if [ "$NEEDS_SUDO" = false ]; then
	echo "setup/ubuntu/app-dell-fan-control - ✓ (already configured)"
	exit 0
fi

# Install i8kutils if not already installed
if ! command -v i8kmon &>/dev/null; then
	echo "setup/ubuntu/app-dell-fan-control - Installing i8kutils"
	sudo apt install -y i8kutils
fi

# Load dell-smm-hwmon module with force if needed
if ! lsmod | grep -q dell_smm_hwmon; then
	echo "setup/ubuntu/app-dell-fan-control - Loading dell_smm_hwmon module"
	sudo modprobe dell_smm_hwmon force=1
fi

# Ensure module loads on boot with force option
if [ ! -f /etc/modprobe.d/dell-smm-hwmon.conf ]; then
	echo "setup/ubuntu/app-dell-fan-control - Configuring dell_smm_hwmon module options"
	sudo tee /etc/modprobe.d/dell-smm-hwmon.conf >/dev/null <<EOF
# Enable Dell SMM hwmon driver for fan control
options dell_smm_hwmon force=1
EOF
fi

# Add module to load on boot
if ! grep -q "dell_smm_hwmon" /etc/modules 2>/dev/null; then
	echo "setup/ubuntu/app-dell-fan-control - Adding dell_smm_hwmon to /etc/modules"
	echo "dell_smm_hwmon" | sudo tee -a /etc/modules >/dev/null
fi

# Install i8kmon configuration
if [ -f "$I8KMON_CONF" ] && ! diff -q "$I8KMON_CONF" /etc/i8kmon.conf &>/dev/null; then
	echo "setup/ubuntu/app-dell-fan-control - Installing i8kmon.conf"
	sudo cp "$I8KMON_CONF" /etc/i8kmon.conf
fi

# Install systemd service for i8kmon
if [ ! -f /etc/systemd/system/i8kmon.service ]; then
	echo "setup/ubuntu/app-dell-fan-control - Installing i8kmon systemd service"
	sudo tee /etc/systemd/system/i8kmon.service >/dev/null <<EOF
[Unit]
Description=Dell laptop fan control daemon
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/i8kmon --daemon --nosid
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

	sudo systemctl daemon-reload
	sudo systemctl enable i8kmon.service
	sudo systemctl start i8kmon.service
fi

echo "setup/ubuntu/app-dell-fan-control - ✓"
