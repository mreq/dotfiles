import sublime_plugin
import re

class ToggleCoffeeBrackets(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]
        line = view.line(sel)
        line_text = view.substr(line)
        if sel.empty():
            selection = None
        else:
            selection = sel
        if re.match(r'^\s*[^\s\(]+\(', line_text):
            new_text = re.sub(r'\((.+)\)', r' \1 ', line_text)
            return view.replace(edit, line, new_text)
        else:
            if selection:
                # wrap the selected text
                new_text = '(' + view.substr(selection).strip() + ')'
                return view.replace(edit, selection, new_text)
            else:
                # wrap the arguments
                new_text = re.sub(r'([^\s\(]+)\s+(.+)$', r'\1(\2)', line_text.rstrip())
                return view.replace(edit, line, new_text)
