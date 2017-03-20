import sublime
import sublime_plugin
import subprocess
import re


class GitShowCommitsOnRemote(sublime_plugin.WindowCommand):

    def run(self):
        cwd = self.window.folders()[0]
        output = subprocess.check_output('git config --get remote.origin.url',
                                         shell=True, cwd=cwd)
        url_base = output.decode('utf8').strip()
        url_base = re.sub('ssh://git@', '', url_base)
        url_base = re.sub('.git', '', url_base)
        url_base = re.sub(':', '/', url_base)

        url = 'https://' + url_base + '/commits'

        if 'gitlab.' in url_base:
            branch = subprocess.check_output('git branch 2> /dev/null',
                                             shell=True, cwd=cwd).decode('utf8').strip()
            url = url + '/' + branch.replace('* ', '')

        run_cmd_parts = ["i3_focus_or_run 'Google-chrome' 'google-chrome'",
                         'xdg-open ' + url]
        run_cmd = '; '.join(run_cmd_parts)
        subprocess.call(run_cmd, shell=True)
