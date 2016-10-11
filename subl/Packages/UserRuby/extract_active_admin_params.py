import sublime
import sublime_plugin
import re

class ExtractActiveAdminParams(sublime_plugin.TextCommand):
    def run(self, edit):
        content = self.view.substr(sublime.Region(0, self.view.size()))
        matches = re.findall(r'\w+\.input :(\w+)', content)

        new_view = self.view.window().new_file()
        new_view.set_scratch(True)

        s = "\n".join(matches)
        new_view.replace(edit, sublime.Region(0, new_view.size()), s)
