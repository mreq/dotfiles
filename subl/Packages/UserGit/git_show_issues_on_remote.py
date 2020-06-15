import sublime
import sublime_plugin
import subprocess
import re

class GitShowIssuesOnRemote(sublime_plugin.WindowCommand):

    def run(self):
        cwd = self.window.folders()[0]
        output = subprocess.check_output('git config --get remote.origin.url',
                                         shell=True,
                                         cwd=cwd)
        url_base = output.decode('utf8').strip()
        url_base = re.sub('ssh://git@', '', url_base)
        url_base = re.sub('git@', '', url_base)
        url_base = re.sub('.git', '', url_base)
        url_base = re.sub(':', '/', url_base)

        if 'bitbucket' in url_base:
            url = 'https://' + url_base + '/issues/?responsible=557058%3A485adbd4-e7f2-4bbe-8160-6104569f89ab&status=open&status=new'
        else:
            url = 'https://' + url_base + '/issues'

        run_cmd_parts = ["i3_focus_or_run 'Google-chrome' 'google-chrome'",
                         'xdg-open "' + url + '"']
        run_cmd = '; '.join(run_cmd_parts)
        subprocess.call(run_cmd, shell=True)
