import sublime_plugin
import re

class StripSpaces(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        line = view.line(view.sel()[0])
        line_text = view.substr(line)
        new_text = line_text.lstrip()
        return view.replace(edit, line, new_text)
