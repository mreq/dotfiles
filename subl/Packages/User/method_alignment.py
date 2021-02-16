import sublime
import sublime_plugin
import re

class MethodAlignment(sublime_plugin.TextCommand):
    def run(self, edit):
        region = self.view.sel()[0]
        rowcol = self.view.rowcol(region.begin())
        sel_line_index = rowcol[0]

        sel_line = self.view.substr(self.view.line(region))
        space_count = len(sel_line) - len(sel_line.lstrip())
        wrong_whitespace = " " * space_count

        index = sel_line_index
        line = sel_line

        lineIndices = []

        while index > 0:
            tp = self.view.text_point(index, 0)
            region = sublime.Region(tp, tp)
            line = self.view.substr(self.view.line(region))
            if space_count > len(line) - len(line.lstrip()):
                break
            else:
                lineIndices.append(index)
                index -= 1

        if index == 0:
            return

        dot_prestring = '.'.join((line.split('.')[:-1]))
        correct_whitespace = " " * len(dot_prestring)

        # replace stored
        for lineIndex in lineIndices:
            tp = self.view.text_point(lineIndex, 0)
            region = sublime.Region(tp, tp)
            line = self.view.line(region)
            line_content = self.view.substr(line)

            replaced = re.sub(r'^\s+', correct_whitespace, line_content)

            self.view.replace(edit, line, replaced)

        # replace following as well
        index = sel_line_index + 1
        while True:
            tp = self.view.text_point(index, 0)
            region = sublime.Region(tp, tp)
            line = self.view.line(region)
            line_content = self.view.substr(line)

            if line_content.startswith(wrong_whitespace):
                replaced = re.sub(r'^\s+', correct_whitespace, line_content)
                self.view.replace(edit, line, replaced)
                index += 1
            else:
                break
