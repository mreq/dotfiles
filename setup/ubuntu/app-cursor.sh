#!/bin/bash

set -e

CURSOR_DIR="$HOME/.local/share/cursor"
CURSOR_APPIMAGE="$CURSOR_DIR/Cursor.AppImage"
ICON_DIR="$HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/cursor-icon.png"

install_cursor() {
	echo "setup/ubuntu/app-cursor - Installing Cursor"

	mkdir -p "$CURSOR_DIR"
	mkdir -p "$ICON_DIR"

	# Check if AppImage exists in Downloads
	DOWNLOAD_APPIMAGE=$(find "$HOME/Downloads" -name "Cursor-*.AppImage" -type f 2>/dev/null | sort -V | tail -1)

	if [[ -n "$DOWNLOAD_APPIMAGE" && -f "$DOWNLOAD_APPIMAGE" ]]; then
		echo "setup/ubuntu/app-cursor - Found AppImage in Downloads: $DOWNLOAD_APPIMAGE"
		cp "$DOWNLOAD_APPIMAGE" "$CURSOR_APPIMAGE"
	else
		echo "setup/ubuntu/app-cursor - Downloading latest Cursor AppImage"

		# Get download URL from Cursor API
		API_RESPONSE=$(curl -s "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable")
		DOWNLOAD_URL=$(echo "$API_RESPONSE" | grep -oP '"downloadUrl"\s*:\s*"\K[^"]+')
		VERSION=$(echo "$API_RESPONSE" | grep -oP '"version"\s*:\s*"\K[^"]+')

		if [[ -z "$DOWNLOAD_URL" ]]; then
			echo "setup/ubuntu/app-cursor - ERROR: Failed to get download URL from Cursor API"
			exit 1
		fi

		echo "setup/ubuntu/app-cursor - Downloading Cursor v$VERSION"
		curl -L "$DOWNLOAD_URL" -o "$CURSOR_APPIMAGE"
	fi

	chmod +x "$CURSOR_APPIMAGE"

	# Extract icon from AppImage
	echo "setup/ubuntu/app-cursor - Extracting icon"
	cd /tmp
	"$CURSOR_APPIMAGE" --appimage-extract cursor.png 2>/dev/null || true
	if [[ -f squashfs-root/cursor.png ]]; then
		cp squashfs-root/cursor.png "$ICON_PATH"
	else
		# Try alternative icon location
		"$CURSOR_APPIMAGE" --appimage-extract usr/share/icons/hicolor/512x512/apps/cursor.png 2>/dev/null || true
		if [[ -f squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png ]]; then
			cp squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png "$ICON_PATH"
		fi
	fi
	rm -rf squashfs-root
	cd - >/dev/null

	echo "setup/ubuntu/app-cursor - Installed to $CURSOR_APPIMAGE"
}

if [[ ! -f "$CURSOR_APPIMAGE" ]]; then
	install_cursor
fi

echo "setup/ubuntu/app-cursor - ✓"
