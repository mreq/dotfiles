#!/bin/bash

exec env ELECTRON_OZONE_PLATFORM_HINT=auto ~/.local/share/cursor/Cursor.AppImage --no-sandbox "$@"
