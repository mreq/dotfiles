import sublime_plugin
import re

class CleanUtfCrap(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]
        line = view.line(sel)
        line_text = view.substr(line)

        replacements = {
            'á': 'á',
            'é': 'é',
            'í': 'í',
            'ó': 'ó',
            'ú': 'ú',
            'ý': 'ý',
            'č': 'č',
            'ř': 'ř',
        }

        for pattern, replacement in replacements.items():
            line_text = line_text.replace(pattern, replacement)

        view.replace(edit, line, line_text)
