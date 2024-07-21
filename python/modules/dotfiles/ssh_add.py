#!/usr/bin/env python3

import subprocess


def ssh_add():
    result = subprocess.run("ssh-add -l", shell=True, capture_output=True, text=True)
    stdout = result.stdout.strip() or None
    if stdout == "The agent has no identities.":
        subprocess.run("ssh-askpass")
