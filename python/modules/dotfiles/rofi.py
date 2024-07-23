#!/usr/bin/env python3

import subprocess


def dmenu(list, color="blue"):
    echo_part = 'echo "' + "\n".join(list) + '"'
    rofi_part = "rofi -dmenu -theme base16-mreq-" + color
    command = echo_part + " | " + rofi_part

    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout.strip() or None


def prompt(color="red"):
    command = "rofi -dmenu -i -theme base16-mreq-" + color

    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout.strip() or None
