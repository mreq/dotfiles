import os
import sublime
import sublime_plugin

class GitStageFromDiff(sublime_plugin.WindowCommand):
    def run(self):
        view = self.window.active_view()
        point = view.text_point(2, 0)
        third_line = view.substr(view.line(point))
        file_name = third_line.replace('--- a/', '')
        os.system('git stage "' + file_name + '"')
