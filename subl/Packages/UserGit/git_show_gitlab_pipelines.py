import sublime
import sublime_plugin
import subprocess
import re


class GitShowGitlabPipelines(sublime_plugin.WindowCommand):

    def run(self):
        cwd = self.window.folders()[0]
        output = subprocess.check_output('git config --get remote.gitlab.url',
                                         shell=True, cwd=cwd)
        url_base = output.decode('utf8').strip()
        url_base = re.sub('git@', '', url_base)
        url_base = re.sub('ssh://', '', url_base)
        url_base = re.sub('.git', '', url_base)
        url_base = re.sub(':', '/', url_base)

        url = 'https://' + url_base + '/-/pipelines/'

        run_cmd_parts = ["i3_focus_or_run 'Google-chrome' 'google-chrome'",
                         'xdg-open ' + url]
        run_cmd = '; '.join(run_cmd_parts)
        subprocess.call(run_cmd, shell=True)
