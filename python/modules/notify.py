#!/usr/bin/env python3
import subprocess


def notification(summary, message=None, app_name=None):
    cmd = ["notify-send"]
    if app_name:
        cmd += ["-a", app_name]
    cmd.append(summary)
    if message:
        cmd.append(message)
    subprocess.run(cmd)
