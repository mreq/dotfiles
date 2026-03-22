import os
import re
import subprocess
import sublime
import sublime_plugin


def get_hunk_lines(file_path):
    """Return list of (start, end) line numbers for each hunk from git diff."""
    directory = os.path.dirname(file_path)
    try:
        output = subprocess.check_output(
            ["git", "diff", "HEAD", "-U0", "--", file_path],
            cwd=directory,
            stderr=subprocess.DEVNULL,
        ).decode("utf-8")
    except subprocess.CalledProcessError:
        return []

    hunks = []
    for match in re.finditer(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", output):
        start = int(match.group(1))
        length = int(match.group(2)) if match.group(2) else 1
        if length == 0:
            # Pure deletion — no lines in working copy, use the line after
            hunks.append((start + 1, start + 1))
        else:
            hunks.append((start, start + length - 1))
    return hunks


class GotoGitHunkCommand(sublime_plugin.TextCommand):

    def run(self, edit, direction="next"):
        file_path = self.view.file_name()
        if not file_path:
            return

        hunks = get_hunk_lines(file_path)
        if not hunks:
            self.view.window().status_message("No git changes")
            return

        cursor_line = self.view.rowcol(self.view.sel()[0].begin())[0] + 1

        forward = direction == "next"
        if forward:
            target = None
            for start, end in hunks:
                if start > cursor_line:
                    target = start
                    break
            if target is None:
                target = hunks[0][0]
        else:
            target = None
            for start, end in reversed(hunks):
                if end < cursor_line:
                    target = end
                    break
            if target is None:
                target = hunks[-1][1]

        point = self.view.text_point(target - 1, 0)
        self.view.sel().clear()
        self.view.sel().add(sublime.Region(point))
        self.view.show(point)
