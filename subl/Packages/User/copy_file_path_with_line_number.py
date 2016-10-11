import sublime
import sublime_plugin
import re

class CopyFilePathWithLineNumber(sublime_plugin.TextCommand):
    def run(self, edit):
        (row, col) = self.view.rowcol(self.view.sel()[0].begin())
        path_from_project = self.view.file_name().replace(self.view.window().folders()[0], '')
        sublime.set_clipboard(path_from_project + ':' + str(row + 1))
