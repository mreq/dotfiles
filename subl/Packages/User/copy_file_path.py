import sublime
import sublime_plugin


class CopyFilePath(sublime_plugin.TextCommand):

    def run(self, edit):
        sublime.set_clipboard(self.get_path())

    def get_path(self):
        return self.view.file_name().replace(
            self.view.window().folders()[0] + '/', '')


class CopyFilePathWithLineNumber(CopyFilePath):

    def get_path(self):
        path = super().get_path()
        (row, col) = self.view.rowcol(self.view.sel()[0].begin())
        return path + ':' + str(row + 1)
