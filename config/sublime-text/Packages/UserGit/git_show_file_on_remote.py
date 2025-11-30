import sublime_plugin
import subprocess
import re


class GitShowFileOnRemote(sublime_plugin.WindowCommand):

    def run(self):
        file_name = self.window.active_view().file_name()
        cwd = self.window.folders()[0]
        path = file_name[file_name.startswith(cwd) and len(cwd) :]

        output = subprocess.check_output(
            "git config --get remote.origin.url", shell=True, cwd=cwd
        )
        url_base = output.decode("utf8").strip()
        url_base = re.sub("git@", "", url_base)
        url_base = re.sub("ssh://", "", url_base)
        url_base = re.sub("\\.git", "", url_base)
        url_base = re.sub(":", "/", url_base)

        branch = (
            subprocess.check_output(
                "git branch 2> /dev/null | grep \*", shell=True, cwd=cwd
            )
            .decode("utf8")
            .strip()
            .replace("* ", "")
        )

        url = "https://" + url_base + "/blob/" + branch + path

        run_cmd_parts = [
            "i3_focus_or_run 'google-chrome' --window-class 'Google-chrome'",
            "xdg-open " + url,
        ]
        run_cmd = "; ".join(run_cmd_parts)
        subprocess.call(run_cmd, shell=True)
