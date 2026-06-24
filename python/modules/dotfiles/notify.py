#!/usr/bin/env python3

import subprocess


def notification(title: str, message: str | None = None, app_name: str | None = None):
    command = ["notify-send"]

    if app_name:
        command.extend(["-a", app_name])

    command.append(title)

    if message:
        command.append(message)

    return subprocess.run(command, check=False)
