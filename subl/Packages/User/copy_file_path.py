import sublime
import sublime_plugin
import subprocess
import re


class CopyFilePath(sublime_plugin.TextCommand):

    def run(self, edit):
        sublime.set_clipboard(self.get_path())

    def get_path(self):
        return self.view.file_name().replace(self.view.window().folders()[0] + '/', '')


class CopyFilePathWithLineNumber(CopyFilePath):

    def get_path(self):
        path = super().get_path()
        (row, col) = self.view.rowcol(self.view.sel()[0].begin())
        return path + ':' + str(row + 1)


class CopyFilePathAsRailsTest(CopyFilePath):

    def get_path(self):
        path = super().get_path()
        return 'PARALLEL_WORKERS=1 r t ' + path

class CopyFilePathAsReactTest(CopyFilePath):

    def get_path(self):
        path = super().get_path()
        return 'bin/test ' + path.replace('frontend/web/', '')

# wip
# class CopyFilePathOnGitRepo(CopyFilePath):

#     def get_path(self):
#         path = super().get_path()
#         git_repo = subprocess.check_output(
#             'git config --get remote.origin.url',
#             shell=True)
#         git_repo = re.search('git@(.+)\.git', str(git_repo)).group(1)
#         git_path = ['https://', git_repo, '/']
#         if 'bitbucket' in git_repo:
#             git_path.append('src/')
#             commit =
#         print(git_path)
#         return path
