import sublime
import sublime_plugin
import subprocess
import re


class GitShowCommitsOnRemote(sublime_plugin.WindowCommand):

    def run(self):
        output = subprocess.check_output('git config --get remote.origin.url',
                                         shell=True, cwd=self.window.folders()[0])
        url_base = output.decode('utf8').strip()
        url_base = re.sub('ssh://git@', '', url_base)
        url_base = re.sub('.git', '', url_base)
        url_base = re.sub(':', '/', url_base)

        url = 'https://' + url_base + '/commits'
        run_cmd_parts = ["i3_focus_or_run 'Google-chrome' 'google-chrome'",
                         'xdg-open ' + url]
        run_cmd = '; '.join(run_cmd_parts)
        print(run_cmd)
        subprocess.call(run_cmd, shell=True)
