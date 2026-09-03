#!/usr/bin/env python3

import subprocess


def run(arguments, input_text=None):
    return subprocess.run(
        ["rofi", *arguments, "-monitor", "-1"],
        input=input_text,
        capture_output=True,
        text=True,
        check=False,
    )


def dmenu(options, color="blue"):
    result = run(
        ["-dmenu", "-theme", "base16-mreq-" + color],
        input_text="\n".join(options) + "\n",
    )
    return result.stdout.strip() or None


def prompt(color="red"):
    result = run(["-dmenu", "-i", "-theme", "base16-mreq-" + color])
    return result.stdout.strip() or None
