import sublime_plugin
import re

class ToggleMathWrap(sublime_plugin.TextCommand):
    def run(self, edit):
        line = self.view.line(self.view.sel()[0])
        line_text = self.view.substr(line)
        if '((' in line_text:
            new_text = re.sub(r'\(\( (.+) \)\)', r'\1', line_text)
        else:
            new_text = re.sub(r'([^:]+: )(.+)', r'\1(( \2 ))', line_text)
        self.view.replace(edit, line, new_text)
