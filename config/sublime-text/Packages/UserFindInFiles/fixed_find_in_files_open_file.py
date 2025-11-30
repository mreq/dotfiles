import sublime
import sublime_plugin
import re
import os


class FixedFindInFilesOpenFileCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        for sel in view.sel():
            line_no = self.get_line_no(sel)
            file_name = self.get_file(sel)
            if line_no and file_name:
                file_loc = "%s:%s" % (file_name, line_no)
                view.window().open_file(file_loc, sublime.ENCODED_POSITION)
            elif file_name:
                view.window().open_file(file_name)

    def get_line_no(self, sel):
        view = self.view
        line_text = view.substr(view.line(sel))
        match = re.match(r"\s*(\d+).+", line_text)
        if match:
            return match.group(1)
        return None

    def get_file(self, sel):
        view = self.view
        line = view.line(sel)
        while line.begin() > 0:
            line_text = view.substr(line)
            match = re.match(r"(.+):$", line_text)
            if match:
                if os.path.exists(os.path.expanduser(match.group(1))):
                    return match.group(1)
            line = view.line(line.begin() - 1)
        return None
