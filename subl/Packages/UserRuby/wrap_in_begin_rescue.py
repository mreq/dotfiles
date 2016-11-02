import sublime
import sublime_plugin
import re

class ToggleBeginRescue(sublime_plugin.TextCommand):
    def run(self, edit):
        # TODO: be able to reverse
        view = self.view
        line = view.line(view.sel()[0])
        line_text = view.substr(line)
        indent = re.match('\s*', line_text).group(0)
        new_text = indent + '\n'.join([
          'begin',
          line_text.replace(indent, '  '),
          'rescue',
          '  binding.pry',
          'end'
        ]).replace('\n', '\n' + indent)
        return view.replace(edit, line, new_text)
