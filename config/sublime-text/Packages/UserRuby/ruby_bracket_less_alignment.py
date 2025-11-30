import sublime_plugin
import re


class ruby_bracket_less_alignment(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]

        line = view.line(sel)
        line_text = view.substr(line)

        argument_matches = re.sub(r"\s+i\s+", "", line_text).split(", ")

        whitespace = (len(argument_matches[0]) + 2) * " "

        first_line = argument_matches[0] + ", " + argument_matches[1]
        lines = [",\n" + whitespace + argument for argument in argument_matches[2:]]

        text = first_line + "".join(lines)

        view.replace(edit, line, text)
