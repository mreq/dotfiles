import os
import subprocess
import re
import time
import sublime
import sublime_plugin


class GitShowFromDiff(sublime_plugin.WindowCommand):

    def run(self):
        view = self.window.active_view()
        row = view.rowcol(view.sel()[0].begin())[0] - 10
        if row < 0:
            row = 0
        col = 0
        target_region = sublime.Region(
            view.text_point(
                row, col), view.text_point(
                row + 20, col))
        first_line = view.substr(view.line(view.text_point(0, 0)))

        before_commit = re.search(r'commit\s+(.+)', first_line).groups()[0]
        target_commit = subprocess.check_output(
            "git log --pretty=oneline | grep -A1 " +
            before_commit +
            " | tail -n1 | awk '{ print $1 }'",
            shell=True).strip().decode('utf-8')

        surrounding_content = view.substr(target_region)
        target_file = re.search('--- a/(.+)', surrounding_content).groups()[0]

        show_arg = target_commit + ':' + target_file
        file_name = '/tmp/git-show-' + str(int(time.time()))

        os.system('git show ' + show_arg + ' > ' + file_name)
        view.window().open_file(file_name, sublime.ENCODED_POSITION)
