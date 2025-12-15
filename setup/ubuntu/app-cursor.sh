#!/bin/bash

set -e

CURSOR_DIR="$HOME/.local/share/cursor"
LATEST_SYMLINK="$CURSOR_DIR/Cursor.AppImage"
ICON_DIR="$HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/cursor-icon.png"

install_cursor() {
	echo "setup/ubuntu/app-cursor - Installing Cursor"

	mkdir -p "$CURSOR_DIR"
	mkdir -p "$ICON_DIR"

	VERSION=""
	TARGET_APPIMAGE=""

	# Check if AppImage exists in Downloads
	DOWNLOAD_APPIMAGE=$(find "$HOME/Downloads" -name "Cursor-*.AppImage" -type f 2>/dev/null | sort -V | tail -1)

	if [[ -n "$DOWNLOAD_APPIMAGE" && -f "$DOWNLOAD_APPIMAGE" ]]; then
		echo "setup/ubuntu/app-cursor - Found AppImage in Downloads: $DOWNLOAD_APPIMAGE"

		# Extract version from filename (e.g., Cursor-1.2.3.AppImage -> 1.2.3)
		FILENAME=$(basename "$DOWNLOAD_APPIMAGE")
		VERSION=$(echo "$FILENAME" | sed -n 's/Cursor-\(.*\)\.AppImage/\1/p')

		if [[ -z "$VERSION" ]]; then
			echo "setup/ubuntu/app-cursor - WARNING: Could not extract version from filename, using 'latest'"
			VERSION="latest"
		fi

		TARGET_APPIMAGE="$CURSOR_DIR/Cursor-$VERSION.AppImage"
		cp "$DOWNLOAD_APPIMAGE" "$TARGET_APPIMAGE"
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

		if [[ -z "$VERSION" ]]; then
			echo "setup/ubuntu/app-cursor - WARNING: Could not extract version from API, using 'latest'"
			VERSION="latest"
		fi

		TARGET_APPIMAGE="$CURSOR_DIR/Cursor-$VERSION.AppImage"
		echo "setup/ubuntu/app-cursor - Downloading Cursor v$VERSION"
		curl -L "$DOWNLOAD_URL" -o "$TARGET_APPIMAGE"
	fi

	chmod +x "$TARGET_APPIMAGE"

	# Extract icon from AppImage
	echo "setup/ubuntu/app-cursor - Extracting icon"
	cd /tmp
	"$TARGET_APPIMAGE" --appimage-extract cursor.png 2>/dev/null || true
	if [[ -f squashfs-root/cursor.png ]]; then
		cp squashfs-root/cursor.png "$ICON_PATH"
	else
		# Try alternative icon location
		"$TARGET_APPIMAGE" --appimage-extract usr/share/icons/hicolor/512x512/apps/cursor.png 2>/dev/null || true
		if [[ -f squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png ]]; then
			cp squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png "$ICON_PATH"
		fi
	fi
	rm -rf squashfs-root
	cd - >/dev/null

	# Create or update symlink to latest version
	if [[ -L "$LATEST_SYMLINK" ]] || [[ -f "$LATEST_SYMLINK" ]]; then
		rm "$LATEST_SYMLINK"
	fi
	ln -s "$(basename "$TARGET_APPIMAGE")" "$LATEST_SYMLINK"

	echo "setup/ubuntu/app-cursor - Installed to $TARGET_APPIMAGE"
	echo "setup/ubuntu/app-cursor - Created symlink: $LATEST_SYMLINK -> $(basename "$TARGET_APPIMAGE")"
}

if [[ ! -f "$LATEST_SYMLINK" ]]; then
	install_cursor
fi

echo "setup/ubuntu/app-cursor - ✓"
