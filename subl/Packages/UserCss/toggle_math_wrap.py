import sublime_plugin
import re

class ToggleMathWrap(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]
        line = view.line(sel)
        line_text = view.substr(line)
        if sel.empty():
            selection = None
        else:
            selection = sel
        if '((' in line_text:
            new_text = re.sub(r'\(\( (.+) \)\)', r'\1', line_text)
            return view.replace(edit, line, new_text)
        else:
            if selection:
                # wrap the selected text
                new_text = '(( ' + view.substr(selection) + ' ))'
                return view.replace(edit, selection, new_text)
            else:
                # wrap the part after colon
                new_text = re.sub(r'([^:]+: )(.+)', r'\1(( \2 ))', line_text)
                return view.replace(edit, line, new_text)
