#!/usr/bin/env python3

import subprocess
import secrets
from datetime import datetime
from .ssh_add import ssh_add
from notify import notification


def generate_filename(extension: str) -> str:
    """Generate a filename with timestamp and random hash.

    Args:
        extension: File extension (without dot)

    Returns:
        Filename in format: timestamp-randomhash.extension
    """
    timestamp = str(round(datetime.timestamp(datetime.now())))
    hash_length = len(timestamp)
    random_hash = secrets.token_hex((hash_length + 1) // 2)[:hash_length]
    return timestamp + "-" + random_hash + "." + extension


def upload_to_server(path: str, filename: str, app_name: str) -> None:
    """Upload a file to s.mreq.eu server and copy URL to clipboard.

    Args:
        path: Local file path to upload
        filename: Remote filename to use on server
        app_name: Application name for notifications
    """
    notification(app_name, message="Uploading to s.mreq.eu.", app_name="sway")

    ssh_add()
    subprocess.run(
        ["scp", path, f"mreq:s.mreq.eu/{filename}"],
        check=True,
    )

    url = f"https://s.mreq.eu/{filename}"
    subprocess.run(["wl-copy", url])

    notification(app_name, message="URL copied to clipboard.", app_name="sway")
