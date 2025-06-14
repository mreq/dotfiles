import sublime
import sublime_plugin
import re

class ruby_dot_chain_alignment(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        sel = view.sel()[0]

        line = view.line(sel)
        line_text = view.substr(line)

        line_text = re.sub("where.not", "whereCUSTOM_DOT_CONNECTIONnot", line_text)
        line_text = re.sub("friendly.find", "friendlyCUSTOM_DOT_CONNECTIONfind", line_text)

        argument_matches = re.sub(r"\s+i\s+", "", line_text).split(".")
        print(argument_matches)

        whitespace = len(argument_matches[0]) * " "

        first_line = argument_matches[0] + "." + argument_matches[1]
        lines = ["\n" + whitespace + "." + re.sub("CUSTOM_DOT_CONNECTION", ".", argument) for argument in argument_matches[2:]]

        text = first_line + "".join(lines)

        view.replace(edit, line, text)
